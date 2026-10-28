@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:dart_test_tools/src/renovate/post_upgrade.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('$PostUpgrade', () {
    late Directory testDir;

    File testFile(String path) => File(join(testDir.path, path));

    Future<void> writeFile(String path, String content) async {
      final file = testFile(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> pubGet() async {
      final result = await Process.run('dart', const [
        'pub',
        'get',
      ], workingDirectory: testDir.path);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    }

    String lockedVersion(String package) {
      final lock = loadYaml(testFile('pubspec.lock').readAsStringSync()) as Map;
      final packages = lock['packages'] as Map;
      return (packages[package] as Map)['version'] as String;
    }

    String? packageVersion(String path) =>
        Pubspec.parse(testFile(join(path, 'pubspec.yaml')).readAsStringSync())
            .version
            ?.toString();

    Iterable<String> changelogLines(String path) =>
        testFile(join(path, 'CHANGELOG.md')).readAsLinesSync();

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
publish_to: none
resolution: workspace
environment:
  sdk: ^3.9.0
dev_dependencies:
  build_runner: ^2.4.0
''');
      await writeFile('packages/a/lib/a.dart', 'const a = 1;\n');
      await writeFile('packages/b/pubspec.yaml', '''
name: b
version: 1.0.0
publish_to: none
resolution: workspace
environment:
  sdk: ^3.9.0
dependencies:
  path: ^1.9.0
''');
      await writeFile('packages/b/lib/b.dart', 'const b = 2;\n');
      await writeFile('packages/b/CHANGELOG.md', '''
# Changelog

## [1.0.0] - 2026-01-01
### Added
- Initial release
''');

      await pubGet();
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test('application mode regenerates root lockfile '
        'when only a member pubspec changed', () async {
      Future<void> setPathConstraint(String from, String to) => writeFile(
        'packages/b/pubspec.yaml',
        testFile('packages/b/pubspec.yaml')
            .readAsStringSync()
            .replaceFirst('path: $from', 'path: $to'),
      );

      await setPathConstraint('^1.9.0', '1.8.0');
      await pubGet();
      expect(lockedVersion('path'), '1.8.0');
      await setPathConstraint('1.8.0', '^1.9.0');

      const sut = PostUpgrade(mode: PostUpgradeMode.application);
      await sut(testDir, const [
        RenovateUpgrade(
          depName: 'path',
          packageFile: 'packages/b/pubspec.yaml',
          depType: 'dependencies',
          currentValue: '1.8.0',
          newValue: '^1.9.0',
        ),
      ]);

      expect(lockedVersion('path'), startsWith('1.9.'));
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('runs build_runner when only a member depends on it', () async {
      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          depName: 'path',
          packageFile: 'packages/b/pubspec.yaml',
        ),
      ]);

      expect(
        Directory(join(testDir.path, '.dart_tool', 'build')).existsSync(),
        isTrue,
      );
    }, timeout: const Timeout(Duration(minutes: 5)));

    test(
      'sdk-only upgrades add sdk changelog lines and one dependencies line',
      () async {
        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [
          RenovateUpgrade(
            depName: 'dart',
            packageFile: 'packages/a/pubspec.yaml',
            currentValue: '^3.9.0',
            newValue: '^3.13.0',
          ),
          RenovateUpgrade(
            depName: 'dart',
            packageFile: 'packages/b/pubspec.yaml',
            currentValue: '^3.9.0',
            newValue: '^3.13.0',
          ),
        ]);

        final lines = changelogLines('packages/b');
        expect(
          lines.where((l) => l == '- Updated min sdk version to ^3.13.0'),
          hasLength(1),
        );
        expect(lines.where((l) => l == '- Updated dependencies'), hasLength(1));
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test('duplicate upgrades for one package produce one patch bump', () async {
      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          depName: 'dart',
          packageFile: 'packages/b/pubspec.yaml',
          newValue: '^3.13.0',
        ),
        RenovateUpgrade(
          depName: 'dart',
          packageFile: 'packages/b/pubspec.yaml',
          newValue: '^3.13.0',
        ),
        RenovateUpgrade(
          depName: 'path',
          packageFile: 'packages/b/pubspec.yaml',
        ),
      ]);

      expect(packageVersion('packages/b'), '1.0.1');
      final lines = changelogLines('packages/b');
      expect(lines, contains(startsWith('## 1.0.1 - ')));
      expect(
        lines.where((l) => l == '- Updated min sdk version to ^3.13.0'),
        hasLength(1),
      );
      expect(lines.where((l) => l == '- Updated dependencies'), hasLength(1));
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('package without version or changelog is skipped', () async {
      final pubspecBefore = testFile('packages/a/pubspec.yaml')
          .readAsStringSync();

      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          depName: 'build_runner',
          packageFile: 'packages/a/pubspec.yaml',
        ),
      ]);

      expect(testFile('packages/a/CHANGELOG.md').existsSync(), isFalse);
      expect(
        testFile('packages/a/pubspec.yaml').readAsStringSync(),
        pubspecBefore,
      );
      expect(testFile('CHANGELOG.md').existsSync(), isFalse);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('package without upgrades is not released', () async {
      final pubspecBefore = testFile('packages/b/pubspec.yaml')
          .readAsStringSync();
      final changelogBefore = testFile('packages/b/CHANGELOG.md')
          .readAsStringSync();

      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          depName: 'build_runner',
          packageFile: 'packages/a/pubspec.yaml',
        ),
      ]);

      expect(
        testFile('packages/b/pubspec.yaml').readAsStringSync(),
        pubspecBefore,
      );
      expect(
        testFile('packages/b/CHANGELOG.md').readAsStringSync(),
        changelogBefore,
      );
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('package with version but without changelog is bumped', () async {
      await writeFile(
        'packages/a/pubspec.yaml',
        testFile('packages/a/pubspec.yaml')
            .readAsStringSync()
            .replaceFirst('name: a\n', 'name: a\nversion: 2.0.0\n'),
      );

      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          depName: 'build_runner',
          packageFile: 'packages/a/pubspec.yaml',
        ),
      ]);

      expect(packageVersion('packages/a'), '2.0.1');
      expect(testFile('packages/a/CHANGELOG.md').existsSync(), isFalse);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('syncs analyzer plugins of the workspace root only', () async {
      await writeFile(
        'pubspec.yaml',
        '${testFile('pubspec.yaml').readAsStringSync()}'
            'dev_dependencies:\n'
            '  path: ^1.9.0\n',
      );
      await writeFile('analysis_options.yaml', 'plugins:\n  path: ^1.8.0\n');
      const memberOptions = 'plugins:\n  path: ^1.8.0\n';
      await writeFile('packages/a/analysis_options.yaml', memberOptions);

      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(depName: 'path', packageFile: 'pubspec.yaml'),
      ]);

      expect(
        testFile('analysis_options.yaml').readAsStringSync(),
        'plugins:\n  path: ^1.9.0\n',
      );
      expect(
        testFile('packages/a/analysis_options.yaml').readAsStringSync(),
        memberOptions,
      );
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
