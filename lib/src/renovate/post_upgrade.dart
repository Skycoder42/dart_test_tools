import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

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
  Future<void> call(Directory repoRoot, List<RenovateUpgrade> upgrades) async {
    final roots = await PubRoots(repoRoot)
        .resolve(upgrades.map((u) => u.packageFile));
    for (final root in roots) {
      await Github.logGroupAsync(
        'Processing ${path.relative(root.path, from: repoRoot.path)}',
        () => _processRoot(repoRoot, root, upgrades),
      );
    }
  }

  Future<void> _processRoot(
    Directory repoRoot,
    Directory root,
    List<RenovateUpgrade> upgrades,
  ) async {
    final pub = await PubWrapper.create(root);
    switch (mode) {
      case .application:
        await pub.upgrade();
      case .library:
        await pub.get();
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
      await _release(repoPath, info, package, upgrades);
    }
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
    await pub.fix().forEach(stdout.writeln);
    await pub.format();
  }

  Future<void> _release(
    String repoPath,
    WorkspaceInfo info,
    PubWrapper pub,
    List<RenovateUpgrade> upgrades,
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
    final packageUpgrades = upgrades
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
