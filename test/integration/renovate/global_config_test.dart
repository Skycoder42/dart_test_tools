@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/renovate/global_config.dart';
import 'package:path/path.dart' show join;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('$GlobalConfig', () {
    late Directory testDir;

    File testFile(String path) => File(join(testDir.path, path));

    Future<void> writeFile(String path, String content) async {
      final file = testFile(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    List<Map<String, dynamic>> packageRules(Map<String, dynamic> config) =>
        (config['packageRules'] as List).cast<Map<String, dynamic>>();

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();

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

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test('contains fixed global values', () async {
      final sut = GlobalConfig(repository: testDir, flutterCompat: false);

      final config = await sut.build();

      expect(config, containsPair('platform', 'github'));
      expect(config, containsPair('onboarding', false));
      expect(config, containsPair('requireConfig', 'required'));
      expect(config, containsPair('binarySource', 'global'));
      expect(config, containsPair('repositoryCache', 'enabled'));
      expect(config, containsPair('executionTimeout', 30));
      expect(
        config,
        containsPair('allowedCommands', [
          r'^renovate-post-upgrade --mode (application|library)$',
        ]),
      );
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('workspace rule lists all workspace package names', () async {
      final sut = GlobalConfig(repository: testDir, flutterCompat: false);

      final config = await sut.build();

      final rules = packageRules(config);
      expect(rules.first, {
        'description': 'Workspace packages are resolved locally',
        'matchManagers': ['pub'],
        'matchPackageNames': ['workspace', 'a', 'b'],
        'enabled': false,
      });
      expect(
        rules.skip(1).expand((r) => r['matchPackageNames'] as List),
        isNot(anyOf(contains('a'), contains('b'), contains('workspace'))),
      );
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('caps test at the version allowed by flutter_test', () async {
      // resolve test together with flutter_test in a separate package to find
      // the newest test version the installed flutter sdk allows
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
      final result = await Process.run('flutter', const [
        'pub',
        'get',
      ], workingDirectory: oracleDir.path);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      final lock = loadYaml(
        File(join(oracleDir.path, 'pubspec.lock')).readAsStringSync(),
      ) as Map;
      final testVersion =
          ((lock['packages'] as Map)['test'] as Map)['version'] as String;

      final sut = GlobalConfig(repository: testDir, flutterCompat: true);

      final config = await sut.build();

      expect(
        packageRules(config),
        contains(
          equals({
            'description': 'Newest resolvable version is $testVersion',
            'matchManagers': ['pub'],
            'matchPackageNames': ['test'],
            'allowedVersions': '<=$testVersion',
          }),
        ),
      );
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('no flutter_test injected if a member depends on it', () async {
      await writeFile('packages/b/pubspec.yaml', '''
name: b
publish_to: none
resolution: workspace
environment:
  sdk: ^3.9.0
dependencies:
  a: ^1.0.0
dev_dependencies:
  flutter_test:
    sdk: flutter
''');
      final pubspecBefore = testFile('pubspec.yaml').readAsStringSync();

      final sut = GlobalConfig(repository: testDir, flutterCompat: true);
      await sut.build();

      expect(testFile('pubspec.yaml').readAsStringSync(), pubspecBefore);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('no flutter_test injected without flutterCompat', () async {
      final pubspecBefore = testFile('pubspec.yaml').readAsStringSync();

      final sut = GlobalConfig(repository: testDir, flutterCompat: false);
      await sut.build();

      expect(testFile('pubspec.yaml').readAsStringSync(), pubspecBefore);
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
