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
    final caps = [
      for (final package in outdated.packages)
        if (!workspacePackages.contains(package.package))
          ?ResolvableCap.fromPackage(package),
    ];
    for (final cap in caps) {
      Github.logInfo(
        'Capping ${cap.package} at resolvable version ${cap.resolvable}: '
        'allowed versions are ${cap.allowedVersions} (latest is ${cap.latest})',
      );
    }

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
      'dependencyDashboardFooter': ?heldBackFooter(
        caps,
        flutterCompat: flutterCompat,
      ),
      'packageRules': [
        {
          'description': 'Workspace packages are resolved locally',
          'matchManagers': ['pub'],
          'matchPackageNames': workspacePackages,
          'enabled': false,
        },
        for (final cap in caps) cap.packageRule,
      ],
    };
  }

  @visibleForTesting
  static String? heldBackFooter(
    List<ResolvableCap> caps, {
    required bool flutterCompat,
  }) {
    if (caps.isEmpty) {
      return null;
    }

    final sb = StringBuffer()
      ..writeln('## Held back updates')
      ..writeln()
      ..write(
        'Non-breaking updates of these dependencies are held back at the '
        'newest version that resolves together with all other dependencies',
      )
      ..writeln(
        flutterCompat
            ? ' and the dependencies pinned by the Flutter SDK.'
            : '.',
      )
      ..writeln(
        'Breaking updates are offered anyway, even if they do not resolve '
        'yet.',
      )
      ..writeln()
      ..writeln('| Package | Resolvable | Held back | Latest |')
      ..writeln('|---|---|---|---|');
    for (final cap in caps) {
      sb.writeln(
        '| `${cap.package}` | ${cap.resolvable} | `${cap.heldBack}` '
        '| ${cap.latest} |',
      );
    }
    return sb.toString().trimRight();
  }
}

@internal
class const ResolvableCap({
  required final String package,
  required final Version resolvable,
  required final Version latest,
}) {
  static ResolvableCap? fromPackage(PackageInfo package) {
    if (package.kind case .root || .transitive) {
      return null;
    }

    final resolvable = package.resolvable?.version;
    final latest = package.latest?.version;
    if (resolvable == null || latest == null || resolvable >= latest) {
      return null;
    }

    return ResolvableCap(
      package: package.package,
      resolvable: resolvable,
      latest: latest,
    );
  }

  Version? get breakingFrom {
    final nextBreaking = resolvable.nextBreaking;
    return latest >= nextBreaking ? nextBreaking : null;
  }

  String get allowedVersions => switch (breakingFrom) {
    null => '<=$resolvable',
    final breaking => '<=$resolvable || >=$breaking',
  };

  String get heldBack => switch (breakingFrom) {
    null => '>$resolvable',
    final breaking => '>$resolvable <$breaking',
  };

  Map<String, dynamic> get packageRule => {
    'description': switch (breakingFrom) {
      null => 'Newest resolvable version is $resolvable',
      _ =>
        'Newest resolvable version is $resolvable, breaking updates stay '
            'allowed',
    },
    'matchManagers': ['pub'],
    'matchPackageNames': [package],
    'allowedVersions': allowedVersions,
  };
}
