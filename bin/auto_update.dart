import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_test_tools/src/auto_update/models/pub/dependency_kind.dart';
import 'package:dart_test_tools/src/auto_update/models/pub/outdated/package_info.dart';
import 'package:dart_test_tools/src/auto_update/pub_wrapper.dart';
import 'package:dart_test_tools/src/tools/github.dart';
import 'package:pub_semver/pub_semver.dart';

void main(List<String> args) => Github.runZoned(() async {
  final targetDir = args.isEmpty
      ? Github.env.githubWorkspace
      : Directory(args.single);
  await _checkUpdateRequired(targetDir);
});

Future<void> _checkUpdateRequired(Directory targetDirectory) async {
  final pub = await PubWrapper.create(targetDirectory);
  final pubspec = await pub.pubspec();
  if (pubspec.resolution == 'workspace') {
    throw Exception('Can only run auto_update on workspace root!');
  }

  // Run upgrade first to ensure dependencies are as up to date as possible
  await pub.upgrade();

  // check for outdated dependencies
  final hasOutdated = await _processOutdated(pub, _isRelevantUpdate);

  // check for outdated sdk versions
  final hasOutdatedSdk = await _checkSdksOutdated(pub);

  // Downgrade all dependencies
  await pub.downgrade();

  // check for security issues
  final hasSecurityUpdates = await _processOutdated(pub, _isSecurityUpdate);

  await Github.env.setOutput('has_outdated', hasOutdated);
  await Github.env.setOutput('has_security_issues', hasSecurityUpdates);
  await Github.env.setOutput('has_outdated_sdk', hasOutdatedSdk);
  await Github.env.setOutput(
    'needs_update',
    hasOutdated || hasSecurityUpdates || hasOutdatedSdk,
  );
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
  if (packageInfo.kind case DependencyKind.root || DependencyKind.transitive) {
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
  final outdated = await pub.deps();
  final dartVersion = outdated.sdks
      .singleWhereOrNull((s) => s.name == 'Dart')
      ?.version;
  final flutterVersion = outdated.sdks
      .singleWhereOrNull((s) => s.name == 'Flutter')
      ?.version;

  final workspaces = await PubWrapper(
    pub.workingDirectory,
    isFlutter: false,
  ).workspaceList();

  var needsUpdate = false;
  for (final info in workspaces.packages) {
    Github.logDebug('Checking SDKs of ${info.name}...');
    final workspacePub = PubWrapper(
      Directory(info.path),
      isFlutter: pub.isFlutter,
    );
    final pubspec = await workspacePub.pubspec();

    final dartConstraint = pubspec.environment['sdk'];
    if (_sdkNeedsUpdate(dartConstraint, dartVersion)) {
      needsUpdate = true;
      Github.logNotice(
        'Dart SDK of ${info.name} needs to be updated to $dartVersion',
      );
    }

    final flutterConstraint = pubspec.environment['flutter'];
    if (_sdkNeedsUpdate(flutterConstraint, flutterVersion)) {
      needsUpdate = true;
      Github.logNotice(
        'Flutter SDK ${info.name} needs to be updated to $flutterVersion',
      );
    }
  }

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
