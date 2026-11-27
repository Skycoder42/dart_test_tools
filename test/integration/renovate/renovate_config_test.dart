@TestOn('dart-vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:path/path.dart';
import 'package:test/scaffolding.dart';
import 'package:yaml/yaml.dart';

import '../_support/run_bin.dart';

void main() {
  group('renovate_config', () {
    final renovateConfigBin = BinRunner('renovate_config');
    late Directory testDir;

    File testFile(String path) => File(join(testDir.path, path));

    Future<void> writeFile(String path, String content) async {
      final file = testFile(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> writeRenovateJson(String preset) => writeFile(
      'renovate.json',
      json.encode({
        'extends': ['github>Skycoder42/dart_test_tools//renovate/$preset'],
      }),
    );

    /// Runs the config generation for the test repository and returns the
    /// generated global config.
    Future<Map<String, dynamic>> renovateConfig() async {
      final output = File('${testDir.path}.config.json');
      addTearDown(output.delete);

      final result = await renovateConfigBin([
        '--repository',
        testDir.path,
        '--output',
        output.path,
      ], workingDirectory: testDir);
      check(result.exitCode, because: result.output).equals(0);

      return json.decode(await output.readAsString()) as Map<String, dynamic>;
    }

    /// Resolves test together with flutter_test in a separate package to find
    /// the newest test version the installed flutter sdk allows.
    Future<String> flutterTestVersion() async {
      final oracleDir = await Directory.systemTemp.createTemp();
      addTearDown(() => oracleDir.delete(recursive: true));
      await File(join(oracleDir.path, 'pubspec.yaml')).writeAsString('''
name: oracle
publish_to: none
environment:
  sdk: ^3.9.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  test: any
''');
      final result = await Process.run(
        'flutter',
        const ['pub', 'get'],
        workingDirectory: oracleDir.path,
        runInShell: Platform.isWindows,
      );
      check(result.exitCode, because: result.output).equals(0);
      final lock = loadYaml(
        File(join(oracleDir.path, 'pubspec.lock')).readAsStringSync(),
      ) as Map;
      return ((lock['packages'] as Map)['test'] as Map)['version'] as String;
    }

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      addTearDown(() => testDir.delete(recursive: true));

      await writeFile('pubspec.yaml', '''
name: workspace
publish_to: none
environment:
  sdk: ^3.9.0
workspace:
  - packages/a
  - packages/b
''');
      await writeFile('packages/a/pubspec.yaml', '''
name: a
version: 1.0.0
publish_to: none
resolution: workspace
environment:
  sdk: ^3.9.0
dev_dependencies:
  test: ^1.25.0
''');
      await writeFile('packages/b/pubspec.yaml', '''
name: b
publish_to: none
resolution: workspace
environment:
  sdk: ^3.9.0
dependencies:
  a: ^1.0.0
''');
    });

    test('fails without a repository', () async {
      final result = await renovateConfigBin(const [
        '--output',
        'config.json',
      ], workingDirectory: testDir);

      check(result.exitCode).equals(1);
      check(result.stderr)
          .isA<String>()
          .contains('Option repository is mandatory.');
    });

    test('caps test at the version allowed by flutter_test for the library '
        'preset', () async {
      await writeRenovateJson('library');
      final testVersion = await flutterTestVersion();

      final config = await renovateConfig();

      check(config['packageRules']).isA<List<dynamic>>()
        ..any(
          .it()
            ..isA<Map<String, dynamic>>().deepEquals({
              'description': 'Workspace packages are resolved locally',
              'matchManagers': ['pub'],
              'matchPackageNames': ['workspace', 'a', 'b'],
              'enabled': false,
            }),
        )
        ..any(
          .it()
            ..isA<Map<String, dynamic>>().deepEquals({
              'description': 'Newest resolvable version is $testVersion',
              'matchManagers': ['pub'],
              'matchPackageNames': ['test'],
              'allowedVersions': '<=$testVersion',
            }),
        );
      check((config['dependencyDashboard'] as Map)['footer'])
          .isA<String>()
          .contains('| `test` | $testVersion | `>$testVersion` |');
    });

    test('keeps the repository untouched for the application preset', () async {
      await writeRenovateJson('application');
      final pubspecBefore = testFile('pubspec.yaml').readAsStringSync();

      final config = await renovateConfig();

      check(config).has('platform', (c) => c['platform']).equals('github');
      check(testFile('pubspec.yaml').readAsStringSync()).equals(pubspecBefore);
    });
  });
}
