import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import '../pub/models/pub/outdated/package_info.dart';
import '../pub/pub_wrapper.dart';
import '../tools/github.dart';
import 'renovate_preset.dart';

@internal
class const GlobalConfig({
  required final Directory repository,
  required final RenovatePreset preset,
}) {
  Future<Map<String, dynamic>> build() async {
    final flutterCompat = preset.flutterCompat;
    Github.logInfo(
      'Using ${preset.name} preset: Flutter SDK compatibility is '
      '${flutterCompat ? 'enforced' : 'not enforced'}',
    );

    final pub = await PubWrapper.create(
      repository,
      forceFlutter: flutterCompat,
    );

    final workspace = await pub.workspaceList();
    final workspacePackages = [
      for (final info in workspace.packages) info.name,
    ];

    if (flutterCompat && !await pub.dependsOnFlutterTest()) {
      await pub.addFlutterTest();
    }

    final outdated = await pub.outdated();

    return {
      'platform': 'github',
      'onboarding': false,
      'requireConfig': 'required',
      'binarySource': 'global',
      'repositoryCache': 'enabled',
      'executionTimeout': 30,
      'allowedCommands': [
        r'^renovate-post-upgrade --mode (application|library)$',
      ],
      'packageRules': [
        {
          'description': 'Workspace packages are resolved locally',
          'matchManagers': ['pub'],
          'matchPackageNames': workspacePackages,
          'enabled': false,
        },
        for (final package in outdated.packages)
          if (!workspacePackages.contains(package.package))
            ?resolvableCap(package),
      ],
    };
  }

  /// Caps non-breaking updates of [package] at its newest resolvable version.
  ///
  /// Breaking updates (from [Version.nextBreaking] of the resolvable version
  /// on) stay allowed, as they need manual handling anyway and must show up in
  /// the dependency dashboard.
  @visibleForTesting
  static Map<String, dynamic>? resolvableCap(PackageInfo package) {
    if (package.kind case .root || .transitive) {
      return null;
    }

    final resolvable = package.resolvable?.version;
    final latest = package.latest?.version;
    if (resolvable == null || latest == null || resolvable >= latest) {
      return null;
    }

    final nextBreaking = resolvable.nextBreaking;
    if (latest >= nextBreaking) {
      Github.logInfo(
        'Capping non-breaking updates of ${package.package} at resolvable '
        'version $resolvable (breaking updates from $nextBreaking on stay '
        'allowed, latest is $latest)',
      );
      return {
        'description':
            'Newest resolvable version is $resolvable, breaking updates '
            'stay allowed',
        'matchManagers': ['pub'],
        'matchPackageNames': [package.package],
        'allowedVersions': '<=$resolvable || >=$nextBreaking',
      };
    }

    Github.logInfo(
      'Capping ${package.package} at resolvable version $resolvable '
      '(latest is $latest)',
    );
    return {
      'description': 'Newest resolvable version is $resolvable',
      'matchManagers': ['pub'],
      'matchPackageNames': [package.package],
      'allowedVersions': '<=$resolvable',
    };
  }
}
