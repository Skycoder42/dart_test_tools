import 'dart:io';

import 'package:meta/meta.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../pub/models/pub/workspace/workspace_info.dart';
import '../pub/pub_wrapper.dart';
import '../tools/github.dart';
import 'models/bump_level.dart';
import 'models/bump_rule.dart';
import 'models/renovate_upgrade.dart';

@internal
enum PostUpgradeMode() {
  application,
  library,
}

@internal
class const PostUpgrade({
  required final PostUpgradeMode mode,
  final PubWrapperFactory pubFactory = const PubWrapperFactory(),
}) {
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
    final hasPubManager = pubUpgrades.isNotEmpty;

    await _mergeWidenedConstraints(repoRoot, pubUpgrades);

    final pub = await pubFactory.create(repoRoot);
    final config = await pub.renovateConfig();
    final ruleMatches = _matchBumpRules(upgrades, config.bumpRules);

    final hasPubOrCustomManagers = upgrades.any(
      (u) =>
          u.manager == _pubManager ||
          config.preBuildExtraManagers.contains(u.manager),
    );
    if (!hasPubOrCustomManagers && ruleMatches.isEmpty) {
      return;
    }

    switch (mode) {
      case .application when !hasPubManager:
      case .library:
        await pub.get();
      case .application:
        await pub.upgrade();
    }

    if (hasPubOrCustomManagers) {
      await _runPreBuildCommand(pub, config.preBuildCommand);
    }

    if (hasPubManager) {
      await _updateAnalyzerPlugins(pub);
      await _autoFix(pub);
    } else if (ruleMatches.isEmpty) {
      return;
    }

    // How pub reports the package paths differs between platforms , so the
    // paths of the repository and of all packages are resolved the same way to
    // compare them
    final repoPath = await repoRoot.resolveSymbolicLinks();
    final workspace = await pub.workspaceList();
    final packagePaths = {
      for (final info in workspace.packages)
        info: await Directory(info.path).resolveSymbolicLinks(),
    };

    for (final MapEntry(key: info, value: packagePath)
        in packagePaths.entries) {
      bool ownedByPackage(RenovateUpgrade upgrade) => path.equals(
        _owner(repoPath, upgrade, packagePaths.values),
        packagePath,
      );

      await _release(
        info,
        await pubFactory.create(Directory(info.path)),
        pubUpgrades.where(ownedByPackage).toList(),
        ruleMatches.where((m) => ownedByPackage(m.upgrade)).toList(),
      );
    }
  }

  /// The absolute path of the workspace package [upgrade] belongs to.
  ///
  /// Pub upgrades belong to the package of their pubspec. All others belong to
  /// the closest workspace package above the updated file, which is at least
  /// the workspace root at [repoPath].
  static String _owner(
    String repoPath,
    RenovateUpgrade upgrade,
    Iterable<String> packagePaths,
  ) {
    final dir = path.join(repoPath, path.dirname(upgrade.packageFile));
    if (upgrade.manager == _pubManager) {
      return dir;
    }
    return packagePaths
        .where((p) => path.equals(p, dir) || path.isWithin(p, dir))
        .fold(repoPath, (a, b) => path.isWithin(a, b) ? b : a);
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
      final pub = pubFactory.dart(
        Directory(path.join(repoRoot.path, path.dirname(upgrade.packageFile))),
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

  /// Checks whether the upper bound of a constraint changed between
  /// [currentValue] and [newValue].
  ///
  /// Returns `true` whenever this cannot be decided reliably, e.g. for missing
  /// or unparsable values.
  @visibleForTesting
  static bool changesUpperBound(String? currentValue, String? newValue) {
    if (currentValue == null || newValue == null) {
      return true;
    }

    final currentBound = _upperBound(currentValue);
    final newBound = _upperBound(newValue);
    if (currentBound == null || newBound == null) {
      return true;
    }

    return currentBound != newBound;
  }

  @visibleForTesting
  static BumpLevel? releaseLevel(
    PostUpgradeMode mode,
    Iterable<RenovateUpgrade> pubUpgrades,
    Iterable<BumpLevel> ruleLevels,
  ) => .maxOf([
    if (pubUpgrades.isNotEmpty &&
        (mode == .application || requiresVersionBump(pubUpgrades)))
      .patch,
    ...ruleLevels,
  ]);

  @visibleForTesting
  static bool requiresVersionBump(Iterable<RenovateUpgrade> upgrades) =>
      upgrades.any(
        (upgrade) =>
            upgrade.isSdkUpgrade ||
            (upgrade.depType != 'dev_dependencies' &&
                changesUpperBound(upgrade.currentValue, upgrade.newValue)),
      );

  static (Version?, bool)? _upperBound(String constraint) {
    try {
      final parsed = constraint.contains('||')
          ? mergeWidenedConstraint(constraint)
          : VersionConstraint.parse(constraint);
      return switch (parsed) {
        VersionRange(:final max, :final includeMax) => (max, includeMax),
        VersionUnion(:final ranges) => (
          ranges.last.max,
          ranges.last.includeMax,
        ),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  List<_RuleMatch> _matchBumpRules(
    List<RenovateUpgrade> upgrades,
    List<BumpRule> rules,
  ) {
    if (rules.isEmpty) {
      return const [];
    }

    final matches = <_RuleMatch>[];
    for (final upgrade in upgrades) {
      final rule = rules.where((r) => r.matches(upgrade)).firstOrNull;
      if (rule == null) {
        if (upgrade.manager != _pubManager) {
          Github.logWarning(
            '${upgrade.manager} upgrade of ${upgrade.depName} in '
            '${upgrade.packageFile} matched no bump rule',
          );
        }
        continue;
      }

      final String message;
      try {
        message = rule.message.render(upgrade);
      } on TemplateException catch (e) {
        throw Exception(
          'Bump rule ${rule.description} matched the ${upgrade.manager} '
          'upgrade of ${upgrade.depName} in ${upgrade.packageFile}, but its '
          'message "${rule.message}" cannot be rendered: ${e.message}',
        );
      }

      Github.logInfo(
        'Bump rule ${rule.description} matched ${upgrade.depName} in '
        '${upgrade.packageFile}: ${rule.bump.name} bump with "$message"',
      );
      matches.add((upgrade: upgrade, level: rule.bump, message: message));
    }
    return matches;
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
    WorkspaceInfo info,
    PubWrapper pub,
    List<RenovateUpgrade> packageUpgrades,
    List<_RuleMatch> matches,
  ) async {
    if (packageUpgrades.isEmpty && matches.isEmpty) {
      Github.logDebug('Skipping package without upgrades: ${info.name}');
      return;
    }

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

    final level = releaseLevel(
      mode,
      packageUpgrades,
      matches.map((m) => m.level),
    );
    if (level == null) {
      Github.logInfo(
        'Skipping release of ${info.name}: no SDK update and no dependency '
        'with a new upper bound',
      );
      return;
    }

    Github.logInfo('Creating ${level.name} update for ${info.name}');
    if (canLogChangelog) {
      final entries = <String>{
        for (final upgrade in packageUpgrades)
          if (upgrade case RenovateUpgrade(
            isSdkUpgrade: true,
            :final newValue?,
          ))
            'Updated min ${upgrade.sdkKey} version to $newValue',
        for (final match in matches) match.message,
        if (packageUpgrades.isNotEmpty) 'Updated dependencies',
      };
      for (final entry in entries) {
        await pub.cider(['log', 'changed', entry]);
      }
    }

    if (canBumpVersion) {
      await pub.cider(['bump', level.name]);
      await pub.cider(const ['version-sync']);
      if (canLogChangelog) {
        await pub.cider(const ['release']);
      }
    }
  }
}

typedef _RuleMatch = ({
  RenovateUpgrade upgrade,
  BumpLevel level,
  String message,
});
