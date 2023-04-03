@TestOn('dart-vm')
library version_sync_test;

import 'dart:io';

import 'package:cider/cider.dart';
// ignore: test_library_import
import 'package:dart_test_tools/cider.dart';
import 'package:test/test.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main() {
  const testVersion = '1.2.3';

  late Directory testDir;
  late Cider cider;

  late File buildGradle;
  late File iosPodspec;
  late File macosPodspec;
  late File dartVersion;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp();

    await _createTestProject(testDir, testVersion);

    buildGradle = File.fromUri(testDir.uri.resolve('android/build.gradle'));
    iosPodspec =
        File.fromUri(testDir.uri.resolve('ios/version_sync_test.podspec'));
    macosPodspec =
        File.fromUri(testDir.uri.resolve('macos/version_sync_test.podspec'));
    dartVersion = File.fromUri(testDir.uri.resolve('lib/src/version.dart'));

    cider = Cider(
      root: testDir,
      plugins: [const VersionSyncPlugin()],
    );
  });

  tearDown(() async {
    await testDir.delete(recursive: true);
  });

  test(
    'versions are updated to $testVersion after sync',
    timeout: const Timeout(Duration(minutes: 2)),
    () async {
      expect(buildGradle.readAsLinesSync(), contains("version '1.0-SNAPSHOT'"));
      expect(
        iosPodspec.readAsLinesSync(),
        contains("  s.version          = '0.0.1'"),
      );
      expect(
        macosPodspec.readAsLinesSync(),
        contains("  s.version          = '0.0.1'"),
      );
      expect(
        dartVersion.readAsLinesSync(),
        contains("const version = '1.5.8';"),
      );

      final result = await cider.run(const ['version-sync']);
      expect(result, 0);

      expect(buildGradle.readAsLinesSync(), contains("version '$testVersion'"));
      expect(
        iosPodspec.readAsLinesSync(),
        contains("  s.version          = '$testVersion'"),
      );
      expect(
        macosPodspec.readAsLinesSync(),
        contains("  s.version          = '$testVersion'"),
      );
      expect(
        dartVersion.readAsLinesSync(),
        contains("const version = '$testVersion';"),
      );
    },
  );

  test(
    'does nothing if pubspec does not contain a version',
    timeout: const Timeout(Duration(minutes: 2)),
    () async {
      final pubspecYaml = File.fromUri(testDir.uri.resolve('pubspec.yaml'));
      final pubspecEdit = YamlEditor(pubspecYaml.readAsStringSync())
        ..remove(const ['version']);
      pubspecYaml.writeAsStringSync(pubspecEdit.toString(), flush: true);

      final result = await cider.run(const ['version-sync']);
      expect(result, 1);

      expect(buildGradle.readAsLinesSync(), contains("version '1.0-SNAPSHOT'"));
      expect(
        iosPodspec.readAsLinesSync(),
        contains("  s.version          = '0.0.1'"),
      );
      expect(
        macosPodspec.readAsLinesSync(),
        contains("  s.version          = '0.0.1'"),
      );
      expect(
        dartVersion.readAsLinesSync(),
        contains("const version = '1.5.8';"),
      );
    },
  );

  test(
    'succeeds if none of the updatable files exist',
    timeout: const Timeout(Duration(minutes: 2)),
    () async {
      buildGradle.deleteSync();
      iosPodspec.deleteSync();
      macosPodspec.deleteSync();
      dartVersion.deleteSync();

      final result = await cider.run(const ['version-sync']);
      expect(result, 0);

      expect(buildGradle.existsSync(), isFalse);
      expect(iosPodspec.existsSync(), isFalse);
      expect(macosPodspec.existsSync(), isFalse);
      expect(dartVersion.existsSync(), isFalse);
    },
  );
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final proc = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  await expectLater(proc.exitCode, completion(0));
}

Future<void> _createTestProject(Directory pwd, String version) async {
  await _run(
    'flutter',
    const [
      'create',
      '--project-name',
      'version_sync_test',
      '--platforms',
      'android',
      '--platforms',
      'ios',
      '--platforms',
      'linux',
      '--platforms',
      'macos',
      '--platforms',
      'windows',
      '--platforms',
      'web',
      '--template',
      'plugin',
      '.'
    ],
    workingDirectory: pwd.path,
  );

  await Directory.fromUri(pwd.uri.resolve('lib/src')).create();
  await File.fromUri(pwd.uri.resolve('lib/src/version.dart'))
      .writeAsString(flush: true, '''
// this is the library version
const version = '1.5.8';
const name = 'version_sync_test';
''');

  final pubspecFile = File.fromUri(pwd.uri.resolve('pubspec.yaml'));
  final pubspecEditor = YamlEditor(await pubspecFile.readAsString())
    ..update(const ['version'], version)
    ..update(const [
      'cider'
    ], {
      'version_sync': const {
        'lib/src/version.dart': {
          'pattern': r"^const version = '.*';$",
          'replacement': "const version = '%{version}';",
        },
      }
    });

  await pubspecFile.writeAsString(pubspecEditor.toString(), flush: true);
}
