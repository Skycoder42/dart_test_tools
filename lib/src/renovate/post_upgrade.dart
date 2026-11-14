import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../pub/models/pub/workspace/workspace_info.dart';
import '../pub/pub_wrapper.dart';
import '../tools/github.dart';
import 'models/renovate_upgrade.dart';
import 'pub_roots.dart';

@internal
enum PostUpgradeMode() {
  application,
  library,
}

@internal
class const PostUpgrade({required final PostUpgradeMode mode}) {
  static const _pubManager = 'pub';
  static const _dependencyKeys = [
    'dependencies',
    'dev_dependencies',
    'dependency_overrides',
  ];

  Future<void> call(Directory repoRoot, List<RenovateUpgrade> upgrades) async {
    if (upgrades.isEmpty) {
      Github.logInfo('No upgrades - nothing to do');
      return;
    }
    final pubUpgrades = upgrades
        .where((u) => u.manager == _pubManager)
        .toList();

    await _mergeWidenedConstraints(repoRoot, pubUpgrades);

    final roots = await _resolveRoots(repoRoot, upgrades);
    for (final (root, managers) in roots) {
      await Github.logGroupAsync(
        'Processing ${path.relative(root.path, from: repoRoot.path)}',
        () => _processRoot(repoRoot, root, managers, pubUpgrades),
      );
    }
  }

  Future<List<(Directory, Set<String>)>> _resolveRoots(
    Directory repoRoot,
    Iterable<RenovateUpgrade> upgrades,
  ) async {
    final pubRoots = PubRoots(repoRoot);
    final roots = <String, Set<String>>{};
    for (final upgrade in upgrades) {
      if (upgrade.manager == _pubManager) {
        final root = await pubRoots.findRoot(upgrade.packageFile);
        (roots[root] ??= {}).add(_pubManager);
      } else {
        // non pub upgrades can only ever be relevant for post commands, which
        // always run in the repository root
        (roots[PubRoots.root] ??= {}).add(upgrade.manager);
      }
    }
    return roots.entries
        .map(
          (entry) => (
            Directory(path.normalize(path.join(repoRoot.path, entry.key))),
            entry.value,
          ),
        )
        .toList();
  }

  Future<void> _mergeWidenedConstraints(
    Directory repoRoot,
    List<RenovateUpgrade> pubUpgrades,
  ) async {
    for (final upgrade in pubUpgrades) {
      final widened = upgrade.newValue;
      if (widened == null || !widened.contains('||')) {
        continue;
      }

      final merged = mergeWidenedConstraint(widened).toString();
      final pub = PubWrapper(
        Directory(path.join(repoRoot.path, path.dirname(upgrade.packageFile))),
        isFlutter: false,
      );
      await pub.pubspecEdit((editor) {
        for (final key in _dependencyKeys) {
          final depKey = [key, upgrade.depName];
          final dependency = editor.parseAt(
            depKey,
            orElse: () => wrapAsYamlNode(null),
          );
          final versionPath = switch (dependency.value) {
            final String version when version == widened => depKey,
            {'version': final String version} when version == widened => [
              ...depKey,
              'version',
            ],
            _ => null,
          };
          if (versionPath != null) {
            editor.update(versionPath, merged);
            Github.logInfo(
              'Merged widened constraint of ${upgrade.depName} in '
              '${upgrade.packageFile}: $widened -> $merged',
            );
          }
        }
      });
    }
  }

  /// Merges a range widened by renovate (`^1.2.0 || ^2.0.0`), which pub does
  /// not support, into a single range covering all parts (`>=1.2.0 <3.0.0`).
  @visibleForTesting
  static VersionRange mergeWidenedConstraint(String constraint) {
    final ranges = [
      for (final part in constraint.split('||'))
        switch (VersionConstraint.parse(part.trim())) {
          final VersionRange range => range,
          final other => throw FormatException(
            'Unsupported part $other in widened constraint',
            constraint,
          ),
        },
    ];

    final lower = ranges.reduce(
      (a, b) => a.min == null || (b.min != null && a.min! <= b.min!) ? a : b,
    );
    final upper = ranges.reduce(
      (a, b) => a.max == null || (b.max != null && a.max! >= b.max!) ? a : b,
    );
    return VersionRange(
      min: lower.min,
      includeMin: lower.includeMin,
      max: upper.max,
      includeMax: upper.includeMax,
    );
  }

  Future<void> _processRoot(
    Directory repoRoot,
    Directory root,
    Set<String> managers,
    List<RenovateUpgrade> pubUpgrades,
  ) async {
    final hasPubManager = managers.contains(_pubManager);
    final pub = await PubWrapper.create(root);
    if (!hasPubManager && !pub.isValid) {
      return;
    }
    final config = await pub.renovateConfig();

    final hasPubOrCustomManagers = {
      _pubManager,
      ...config.preBuildExtraManagers,
    }.intersection(managers).isNotEmpty;
    if (!hasPubOrCustomManagers) {
      return;
    }

    switch (mode) {
      case .application when !hasPubManager:
      case .library:
        await pub.get();
      case .application:
        await pub.upgrade();
    }

    await _runPreBuildCommand(pub, config.preBuildCommand);
    if (!hasPubManager) {
      return;
    }

    await _updateAnalyzerPlugins(pub);
    await _autoFix(pub);

    final workspace = await pub.workspaceList();
    final packages = [
      for (final info in workspace.packages)
        (info, PubWrapper(Directory(info.path), isFlutter: pub.isFlutter)),
    ];

    final repoPath = await repoRoot.resolveSymbolicLinks();
    for (final (info, package) in packages) {
      await _release(repoPath, info, package, pubUpgrades);
    }
  }

  Future<void> _runPreBuildCommand(PubWrapper pub, String? command) async {
    if (command == null) {
      Github.logDebug('No pre-build command configured');
      return;
    }

    await Github.logGroupAsync(
      'Running pre-build command',
      () async => await pub.runShellCommand(command),
    );
  }

  Future<void> _updateAnalyzerPlugins(PubWrapper pub) async {
    final plugins = await pub.analysisOptionsPlugins();
    if (plugins.isEmpty) {
      return;
    }

    final pubspec = await pub.pubspec();
    await pub.analysisOptionsEdit((editor) {
      for (final MapEntry(key: plugin, value: currentConstraint)
          in plugins.entries) {
        final dependency =
            pubspec.dependencies[plugin] ?? pubspec.devDependencies[plugin];
        if (dependency is! HostedDependency) {
          throw Exception(
            'Analyzer plugin $plugin is declared in the '
            'analysis_options.yaml of ${pubspec.name} but is not a hosted '
            'dependency in its pubspec.yaml',
          );
        }

        final constraint = dependency.version.toString();
        if (constraint == currentConstraint) {
          continue;
        }

        editor.update(['plugins', plugin], constraint);
        Github.logInfo(
          'Updated plugin $plugin in ${pubspec.name} to $constraint',
        );
      }
    });
  }

  Future<void> _autoFix(PubWrapper pub) async {
    if (await pub.dependsOnBuildRunner()) {
      await pub.runBuildRunner();
    }

    await pub.format();
    await pub.fix().forEach(print);
    await pub.format();
  }

  Future<void> _release(
    String repoPath,
    WorkspaceInfo info,
    PubWrapper pub,
    List<RenovateUpgrade> pubUpgrades,
  ) async {
    final pubspec = await pub.pubspec();
    if (pubspec.workspace case List(isEmpty: false)) {
      Github.logDebug('Skipping workspace package: ${info.name}');
      return;
    }
    final canLogChangelog = pub.hasChangelog;
    final canBumpVersion = pubspec.version != null;
    if (!canLogChangelog && !canBumpVersion) {
      Github.logDebug('Skipping package ${info.name} - nothing to release');
      return;
    }

    final packagePath = await pub.workingDirectory.resolveSymbolicLinks();
    final packageDir = path.posix.joinAll(
      path.split(path.relative(packagePath, from: repoPath)),
    );
    final packageUpgrades = pubUpgrades
        .where((u) => _packageDir(u) == packageDir)
        .toList();
    if (packageUpgrades.isEmpty) {
      Github.logDebug('Skipping package without upgrades: ${info.name}');
      return;
    }

    Github.logInfo('Creating update for ${info.name}');
    if (canLogChangelog) {
      final sdkEntries = {
        for (final upgrade in packageUpgrades)
          if (upgrade case RenovateUpgrade(
            isSdkUpgrade: true,
            :final newValue?,
          ))
            'Updated min ${upgrade.sdkKey} version to $newValue',
      };
      for (final entry in sdkEntries) {
        await pub.cider(['log', 'changed', entry]);
      }
      await pub.cider(const ['log', 'changed', 'Updated dependencies']);
    }

    if (canBumpVersion) {
      await pub.cider(const ['bump', 'patch']);
      await pub.cider(const ['version-sync']);
      if (canLogChangelog) {
        await pub.cider(const ['release']);
      }
    }
  }

  static String _packageDir(RenovateUpgrade upgrade) =>
      path.posix.normalize(path.posix.dirname(upgrade.packageFile));
}
