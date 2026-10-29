import 'dart:io';

import 'package:meta/meta.dart';

import '../pub/models/pub/outdated/package_info.dart';
import '../pub/pub_wrapper.dart';
import '../tools/github.dart';

@internal
class const GlobalConfig({
  required final Directory repository,
  required final bool flutterCompat,
}) {
  Future<Map<String, dynamic>> build() async {
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
            ?_resolvableCap(package),
      ],
    };
  }

  Map<String, dynamic>? _resolvableCap(PackageInfo package) {
    if (package.kind case .root || .transitive) {
      return null;
    }

    final resolvable = package.resolvable?.version;
    final latest = package.latest?.version;
    if (resolvable == null || latest == null || resolvable == latest) {
      return null;
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
