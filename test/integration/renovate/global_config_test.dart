@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/pub/models/pub/dependency_kind.dart';
import 'package:dart_test_tools/src/pub/models/pub/outdated/package_info.dart';
import 'package:dart_test_tools/src/pub/models/pub/outdated/version_info.dart';
import 'package:dart_test_tools/src/renovate/global_config.dart';
import 'package:dart_test_tools/src/renovate/renovate_preset.dart';
import 'package:path/path.dart' show join;
import 'package:pub_semver/pub_semver.dart';
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
      final sut = GlobalConfig(
        repository: testDir,
        preset: RenovatePreset.application,
      );

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
      final sut = GlobalConfig(
        repository: testDir,
        preset: RenovatePreset.application,
      );

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
      final result = await Process.run(
        'flutter',
        const ['pub', 'get'],
        workingDirectory: oracleDir.path,
        runInShell: Platform.isWindows,
      );
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      final lock = loadYaml(
        File(join(oracleDir.path, 'pubspec.lock')).readAsStringSync(),
      ) as Map;
      final testVersion =
          ((lock['packages'] as Map)['test'] as Map)['version'] as String;

      final sut = GlobalConfig(
        repository: testDir,
        preset: RenovatePreset.library,
      );

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

      final sut = GlobalConfig(
        repository: testDir,
        preset: RenovatePreset.library,
      );
      await sut.build();

      expect(testFile('pubspec.yaml').readAsStringSync(), pubspecBefore);
    }, timeout: const Timeout(Duration(minutes: 5)));

    group('resolvableCap', () {
      PackageInfo info(
        String resolvable,
        String latest, {
        DependencyKind kind = DependencyKind.direct,
      }) => PackageInfo(
        package: 'pkg',
        kind: kind,
        resolvable: VersionInfo(version: Version.parse(resolvable)),
        latest: VersionInfo(version: Version.parse(latest)),
      );

      test('returns null if resolvable is latest', () {
        expect(GlobalConfig.resolvableCap(info('1.2.3', '1.2.3')), isNull);
      });

      test('returns null for transitive and root packages', () {
        for (final kind in [DependencyKind.transitive, DependencyKind.root]) {
          expect(
            GlobalConfig.resolvableCap(info('1.2.3', '1.3.0', kind: kind)),
            isNull,
          );
        }
      });

      test('caps minor and patch updates', () {
        expect(GlobalConfig.resolvableCap(info('13.3.0', '13.5.1')), {
          'description': 'Newest resolvable version is 13.3.0',
          'matchManagers': ['pub'],
          'matchPackageNames': ['pkg'],
          'allowedVersions': '<=13.3.0',
        });
      });

      test('keeps major updates allowed', () {
        expect(GlobalConfig.resolvableCap(info('13.3.0', '14.7.0')), {
          'description':
              'Newest resolvable version is 13.3.0, breaking updates '
              'stay allowed',
          'matchManagers': ['pub'],
          'matchPackageNames': ['pkg'],
          'allowedVersions': '<=13.3.0 || >=14.0.0',
        });
      });

      test('treats 0.x minor updates as breaking', () {
        expect(
          GlobalConfig.resolvableCap(info('0.14.12', '0.15.2')),
          containsPair('allowedVersions', '<=0.14.12 || >=0.15.0'),
        );
        expect(
          GlobalConfig.resolvableCap(info('0.14.12', '0.14.20')),
          containsPair('allowedVersions', '<=0.14.12'),
        );
      });
    });

    test('no flutter_test injected for the application preset', () async {
      final pubspecBefore = testFile('pubspec.yaml').readAsStringSync();

      final sut = GlobalConfig(
        repository: testDir,
        preset: RenovatePreset.application,
      );
      await sut.build();

      expect(testFile('pubspec.yaml').readAsStringSync(), pubspecBefore);
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
