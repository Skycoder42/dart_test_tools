import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../pub/pub_wrapper.dart';
import '../tools/github.dart';

@internal
enum FlutterCompatResult() {
  compatible,
  incompatible,
  nothingToCheck,
}

@internal
class FlutterCompatException(final String message) implements Exception {
  @override
  String toString() => 'FlutterCompatException: $message';
}

@internal
class FlutterCompat({
  required final Directory directory,
  @visibleForTesting final String flutterExecutable = 'flutter',
}) {
  // exit code of cmd if a command was not found
  static const _windowsCommandNotFound = 9009;

  static const _missingFlutterMessage =
      'flutter was not found in the PATH. Install flutter or rerun '
      'setup_hooks with --no-flutter-compat.';

  Future<FlutterCompatResult> call() async {
    if (!File(join(directory.path, 'pubspec.yaml')).existsSync()) {
      throw FlutterCompatException(
        'No pubspec.yaml found in ${directory.path}.',
      );
    }

    final packages = await _findPackages();
    if (packages.isEmpty) {
      Github.logInfo(
        'No published dart packages found, nothing to check for flutter '
        'compatibility.',
      );
      return .nothingToCheck;
    }

    Github.logInfo(
      'Checking flutter compatibility of: '
      '${packages.map((package) => package.pubspec.name).join(', ')}',
    );
    final versions = await _flutterVersions();
    final sdksCompatible = _checkSdks(packages, versions);
    final dependenciesCompatible = await _checkDependencies(
      packages,
      versions.dart,
    );
    return sdksCompatible && dependenciesCompatible
        ? .compatible
        : .incompatible;
  }

  Future<List<({String path, Pubspec pubspec})>> _findPackages() async {
    final workspaces = await PubWrapper(
      directory,
      isFlutter: false,
    ).workspaceList();

    final packages = <({String path, Pubspec pubspec})>[];
    for (final package in workspaces.packages) {
      final pubspecFile = File(join(package.path, 'pubspec.yaml'));
      final pubspec = Pubspec.parse(
        await pubspecFile.readAsString(),
        sourceUrl: pubspecFile.uri,
      );

      if (pubspec.publishTo == 'none') {
        Github.logInfo('Skipping ${pubspec.name}: it is not published.');
      } else if (pubspec.dependencies.values.any(_isFlutterSdk)) {
        Github.logInfo('Skipping ${pubspec.name}: it depends on flutter.');
      } else {
        packages.add((path: package.path, pubspec: pubspec));
      }
    }
    return packages;
  }

  bool _isFlutterSdk(Dependency dependency) =>
      dependency is SdkDependency && dependency.sdk == 'flutter';

  Future<({Version dart, Version flutter})> _flutterVersions() async {
    final ProcessResult result;
    try {
      result = await Process.run(flutterExecutable, const [
        '--version',
        '--machine',
      ], runInShell: Platform.isWindows);
    } on ProcessException {
      throw FlutterCompatException(_missingFlutterMessage);
    }

    if (Platform.isWindows && result.exitCode == _windowsCommandNotFound) {
      throw FlutterCompatException(_missingFlutterMessage);
    }
    if (result.exitCode != 0) {
      throw Exception(
        'flutter --version failed with exit code ${result.exitCode}: '
        '${result.stderr}',
      );
    }

    final versions =
        json.decode(result.stdout as String) as Map<String, dynamic>;
    return (
      dart: Version.parse(versions['dartSdkVersion'] as String),
      flutter: Version.parse(versions['frameworkVersion'] as String),
    );
  }

  bool _checkSdks(
    List<({String path, Pubspec pubspec})> packages,
    ({Version dart, Version flutter}) versions,
  ) {
    var compatible = true;
    for (final (path: _, :pubspec) in packages) {
      final dartConstraint = pubspec.environment['sdk'];
      if (dartConstraint != null && !dartConstraint.allows(versions.dart)) {
        stderr.writeln(
          '${pubspec.name} requires dart $dartConstraint, but flutter '
          '${versions.flutter} comes with dart ${versions.dart}.',
        );
        compatible = false;
      }

      final flutterConstraint = pubspec.environment['flutter'];
      if (flutterConstraint != null &&
          !flutterConstraint.allows(versions.flutter)) {
        stderr.writeln(
          '${pubspec.name} requires flutter $flutterConstraint, but flutter '
          '${versions.flutter} is installed.',
        );
        compatible = false;
      }
    }
    return compatible;
  }

  Future<bool> _checkDependencies(
    List<({String path, Pubspec pubspec})> packages,
    Version dartVersion,
  ) async {
    final probe = await Directory.systemTemp.createTemp('flutter_compat_');
    try {
      await File(join(probe.path, 'pubspec.yaml'))
          .writeAsString(_probePubspec(packages, dartVersion));
      final exitCode = await Github.exec(
        flutterExecutable,
        const ['pub', 'get'],
        workingDirectory: probe,
        runInShell: Platform.isWindows,
        expectedExitCode: null,
      );
      return exitCode == 0;
    } finally {
      await probe.delete(recursive: true);
    }
  }

  String _probePubspec(
    List<({String path, Pubspec pubspec})> packages,
    Version dartVersion,
  ) {
    final pathDependencies = {
      for (final (:path, :pubspec) in packages) pubspec.name: {'path': path},
    };
    final editor = YamlEditor('')
      ..update(const [], {
        'name': 'flutter_compat_check',
        'publish_to': 'none',
        'environment': {'sdk': '^$dartVersion'},
        'dependencies': {
          'flutter': {'sdk': 'flutter'},
          'flutter_test': {'sdk': 'flutter'},
          'flutter_localizations': {'sdk': 'flutter'},
          ...pathDependencies,
        },
        // resolves hosted dependencies between the packages to the path ones
        'dependency_overrides': pathDependencies,
      });
    return editor.toString();
  }
}
