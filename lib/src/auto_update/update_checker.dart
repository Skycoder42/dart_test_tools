import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import '../tools/github.dart';
import 'models/pub/dependency_kind.dart';
import 'models/pub/outdated/package_info.dart';
import 'pub_wrapper.dart';
import 'sdk_iterator.dart';

class UpdateChecker {
  final bool flutterCompat;

  const UpdateChecker({required this.flutterCompat});

  Future<void> call(Directory targetDirectory) async {
    final pub = await PubWrapper.create(
      targetDirectory,
      forceFlutter: flutterCompat,
    );
    final pubspec = await pub.pubspec();
    if (pubspec.resolution == 'workspace') {
      throw Exception('Can only run auto_update on workspace root!');
    }

    // Downgrade all dependencies
    await pub.downgrade();

    // check for security issues
    final hasSecurityUpdates = await _processOutdated(pub, _isSecurityUpdate);

    // Temporarily add flutter_test to keep resolution compatible with the
    // current flutter sdk, matching what the updater does before upgrading.
    final needsFlutterTest = flutterCompat && !await pub.dependsOnFlutterTest();
    if (needsFlutterTest) {
      await pub.addFlutterTest();
    }

    try {
      // Run upgrade first to ensure dependencies are as up to date as possible
      await pub.upgrade();

      // check for outdated dependencies
      final hasOutdated = await _processOutdated(pub, _isRelevantUpdate);

      // check for outdated sdk versions
      final hasOutdatedSdk = await _checkSdksOutdated(pub);

      await Github.env.setOutput('has_outdated', hasOutdated);
      await Github.env.setOutput('has_security_issues', hasSecurityUpdates);
      await Github.env.setOutput('has_outdated_sdk', hasOutdatedSdk);
      await Github.env.setOutput(
        'needs_update',
        hasOutdated || hasSecurityUpdates || hasOutdatedSdk,
      );
    } finally {
      if (needsFlutterTest) {
        await pub.removeFlutterTest();
        await pub.upgrade();
      }
    }
  }

  Future<bool> _processOutdated(
    PubWrapper pub,
    bool Function(PackageInfo event) filter,
  ) async {
    final outdated = await pub.outdated();
    return outdated.packages.where(filter).toList().isNotEmpty;
  }

  bool _isRelevantUpdate(PackageInfo packageInfo) {
    if (!_hasCorrectKind(packageInfo)) {
      return false;
    }

    if (_hasSecurityIssue(packageInfo)) {
      return true;
    }

    final currentVersion = packageInfo.current?.version;
    final resolvableVersion = packageInfo.resolvable?.version;
    if (currentVersion == resolvableVersion) {
      Github.logDebug('Dependency $packageInfo is up to date');
      return false;
    }

    Github.logNotice('Dependency $packageInfo needs to be updated');
    return true;
  }

  bool _isSecurityUpdate(PackageInfo packageInfo) {
    if (!_hasCorrectKind(packageInfo)) {
      return false;
    }

    if (_hasSecurityIssue(packageInfo)) {
      return true;
    }

    Github.logDebug('Dependency $packageInfo is secure');
    return false;
  }

  bool _hasCorrectKind(PackageInfo packageInfo) {
    if (packageInfo.kind
        case DependencyKind.root || DependencyKind.transitive) {
      // Github.logDebug('Skipping non direct dependency $packageInfo');
      return false;
    }

    return true;
  }

  bool _hasSecurityIssue(PackageInfo packageInfo) {
    if (packageInfo.isDiscontinued ||
        packageInfo.isCurrentRetracted ||
        packageInfo.isCurrentAffectedByAdvisory) {
      Github.logWarning('Dependency $packageInfo has critical status');
      return true;
    }

    return false;
  }

  Future<bool> _checkSdksOutdated(PubWrapper pub) async {
    final sdkIterator = SdkIterator(pub);

    var needsUpdate = false;
    await sdkIterator.iterate((name, pub, dartVersion, flutterVersion) async {
      Github.logDebug('Checking SDKs of $name...');
      final pubspec = await pub.pubspec();

      final dartConstraint = pubspec.environment['sdk'];
      if (_sdkNeedsUpdate(dartConstraint, dartVersion)) {
        needsUpdate = true;
        Github.logNotice(
          'Dart SDK of $name needs to be updated to $dartVersion',
        );
      }

      final flutterConstraint = pubspec.environment['flutter'];
      if (_sdkNeedsUpdate(flutterConstraint, flutterVersion)) {
        needsUpdate = true;
        Github.logNotice(
          'Flutter SDK $name needs to be updated to $flutterVersion',
        );
      }
    });
    return needsUpdate;
  }

  bool _sdkNeedsUpdate(VersionConstraint? constraint, Version? version) {
    final minVersion = switch (constraint) {
      null => null,
      final Version version => version,
      final VersionRange range => range.min,
      _ => throw Exception('Cannot process version unions'),
    };

    if (minVersion == null || version == null) {
      return false;
    }

    final nextMin = minVersion.nextMinor;
    return version >= nextMin;
  }
}
