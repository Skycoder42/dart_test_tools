import 'dart:io';

import 'package:dart_test_tools/src/auto_update/models/pub/dependency_kind.dart';
import 'package:dart_test_tools/src/auto_update/models/pub/outdated/package_info.dart';
import 'package:dart_test_tools/src/auto_update/pub_wrapper.dart';
import 'package:dart_test_tools/src/tools/github.dart';

void main(List<String> args) => Github.runZoned(() async {
  final targetDir = args.isEmpty
      ? Github.env.githubWorkspace
      : Directory(args.single);
  await _checkUpdateRequired(targetDir);
});

Future<void> _checkUpdateRequired(Directory targetDirectory) async {
  final pubWrapper = await PubWrapper.create(targetDirectory);

  // Run upgrade first to ensure dependencies are as up to date as possible
  await pubWrapper.upgrade();

  // check for outdated dependencies
  final hasOutdated = await _processOutdated(pubWrapper, _isRelevantUpdate);

  // Downgrade all dependencies
  await pubWrapper.downgrade();

  // check for security issues
  final hasSecurityUpdates = await _processOutdated(
    pubWrapper,
    _isSecurityUpdate,
  );

  await Github.env.setOutput('has_outdated', hasOutdated);
  await Github.env.setOutput('has_security_issues', hasSecurityUpdates);
}

Future<bool> _processOutdated(
  PubWrapper pubWrapper,
  bool Function(PackageInfo event) filter,
) async {
  final outdated = await pubWrapper.outdated();
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
