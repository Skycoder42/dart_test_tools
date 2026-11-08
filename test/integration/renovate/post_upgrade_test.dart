@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:dart_test_tools/src/renovate/post_upgrade.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
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
          manager: 'pub',
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
          manager: 'pub',
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
            manager: 'pub',
            depName: 'dart',
            packageFile: 'packages/a/pubspec.yaml',
            currentValue: '^3.9.0',
            newValue: '^3.13.0',
          ),
          RenovateUpgrade(
            manager: 'pub',
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
          manager: 'pub',
          depName: 'dart',
          packageFile: 'packages/b/pubspec.yaml',
          newValue: '^3.13.0',
        ),
        RenovateUpgrade(
          manager: 'pub',
          depName: 'dart',
          packageFile: 'packages/b/pubspec.yaml',
          newValue: '^3.13.0',
        ),
        RenovateUpgrade(
          manager: 'pub',
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
          manager: 'pub',
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
          manager: 'pub',
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
          manager: 'pub',
          depName: 'build_runner',
          packageFile: 'packages/a/pubspec.yaml',
        ),
      ]);

      expect(packageVersion('packages/a'), '2.0.1');
      expect(testFile('packages/a/CHANGELOG.md').existsSync(), isFalse);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('only non-pub upgrades run nothing and change nothing', () async {
      Map<String, DateTime> snapshot() => {
        for (final entity in testDir.listSync(recursive: true))
          if (entity is File) entity.path: entity.lastModifiedSync(),
      };
      final before = snapshot();

      const sut = PostUpgrade(mode: PostUpgradeMode.application);
      await sut(testDir, const [
        RenovateUpgrade(
          manager: 'npm',
          depName: 'renovate',
          packageFile: 'tool/renovate/package.json',
          currentValue: '44.164.5',
          newValue: '44.170.0',
        ),
      ]);

      expect(snapshot(), before);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('non-pub upgrades are ignored next to pub upgrades', () async {
      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          manager: 'npm',
          depName: 'renovate',
          packageFile: 'tool/renovate/package.json',
          currentValue: '44.164.5',
          newValue: '44.170.0',
        ),
        RenovateUpgrade(
          manager: 'pub',
          depName: 'path',
          packageFile: 'packages/b/pubspec.yaml',
        ),
      ]);

      expect(packageVersion('packages/b'), '1.0.1');
      final lines = changelogLines('packages/b');
      expect(lines.where((l) => l.startsWith('## ')), hasLength(2));
      expect(lines.where((l) => l == '- Updated dependencies'), hasLength(1));
      expect(testFile('tool/renovate/CHANGELOG.md').existsSync(), isFalse);
    }, timeout: const Timeout(Duration(minutes: 5)));

    group('pre-build command', () {
      const pathUpgrade = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'packages/b/pubspec.yaml',
      );

      Future<void> setPreBuildCommand(String config) => writeFile(
        'pubspec.yaml',
        '${testFile('pubspec.yaml').readAsStringSync()}'
            'renovate:\n'
            '  pre_build_command:$config\n',
      );

      test('runs in the workspace root', () async {
        await setPreBuildCommand(' echo ok > marker.txt');

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [pathUpgrade]);

        expect(testFile('marker.txt').readAsStringSync(), 'ok\n');
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('runs multi line scripts', () async {
        await setPreBuildCommand(r'''
 |
    mkdir -p out
    cd out
    greeting=hello
    echo "$greeting" > first.txt
    echo world >> first.txt
    cp first.txt ../second.txt''');

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [pathUpgrade]);

        expect(testFile('out/first.txt').readAsStringSync(), 'hello\nworld\n');
        expect(testFile('second.txt').readAsStringSync(), 'hello\nworld\n');
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('runs before build_runner', () async {
        // The builder of a imports a library with a missing part, so
        // build_runner cannot compile its build script until the pre-build
        // command created the part.
        await writeFile(
          'packages/a/pubspec.yaml',
          testFile('packages/a/pubspec.yaml').readAsStringSync().replaceFirst(
            'dev_dependencies:',
            'dependencies:\n  build: ^4.0.0\ndev_dependencies:',
          ),
        );
        await writeFile('packages/a/build.yaml', '''
builders:
  noop:
    import: package:a/builder.dart
    builder_factories:
      - noopBuilder
    build_extensions:
      .noop:
        - .noop.out
    auto_apply: none
''');
        await writeFile('packages/a/lib/builder.dart', '''
import 'package:build/build.dart';

part 'builder.g.dart';

Builder noopBuilder(BuilderOptions options) => createBuilder();
''');
        await writeFile('packages/a/builder.g.dart.in', '''
part of 'builder.dart';

Builder createBuilder() => _NoopBuilder();

class _NoopBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    '.noop': ['.noop.out'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {}
}
''');
        await pubGet();

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await expectLater(sut(testDir, const [pathUpgrade]), throwsException);

        await setPreBuildCommand(
          ' cp packages/a/builder.g.dart.in packages/a/lib/builder.g.dart',
        );
        await sut(testDir, const [pathUpgrade]);

        expect(testFile('packages/a/lib/builder.g.dart').existsSync(), isTrue);
      }, timeout: const Timeout(Duration(minutes: 10)));

      test('fails if the command fails', () async {
        await setPreBuildCommand(' exit 3');

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await expectLater(sut(testDir, const [pathUpgrade]), throwsException);
      }, timeout: const Timeout(Duration(minutes: 5)));
    }, testOn: 'posix');

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
        RenovateUpgrade(
          manager: 'pub',
          depName: 'path',
          packageFile: 'pubspec.yaml',
        ),
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

    test('merges widened constraints before resolving', () async {
      await writeFile('packages/b/pubspec.yaml', '''
name: b
version: 1.0.0
publish_to: none
resolution: workspace
environment:
  sdk: ^3.9.0
dependencies:
  path: ^1.8.0 || ^1.9.0
dev_dependencies:
  meta:
    hosted: https://pub.dev
    version: ^1.15.0 || ^1.16.0
''');

      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          manager: 'pub',
          depName: 'path',
          packageFile: 'packages/b/pubspec.yaml',
          currentValue: '^1.8.0',
          newValue: '^1.8.0 || ^1.9.0',
        ),
        RenovateUpgrade(
          manager: 'pub',
          depName: 'meta',
          packageFile: 'packages/b/pubspec.yaml',
          currentValue: '^1.15.0',
          newValue: '^1.15.0 || ^1.16.0',
        ),
      ]);

      final pubspec = testFile('packages/b/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('  path: ">=1.8.0 <2.0.0"\n'));
      expect(pubspec, contains('    version: ">=1.15.0 <2.0.0"\n'));
      expect(testFile('pubspec.lock').existsSync(), isTrue);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('merges widened constraints next to empty sections', () async {
      await writeFile('packages/b/pubspec.yaml', '''
name: b
version: 1.0.0
publish_to: none
resolution: workspace
environment:
  sdk: ^3.9.0
dependencies:
dev_dependencies:
  path: ^1.8.0 || ^1.9.0
''');

      const sut = PostUpgrade(mode: PostUpgradeMode.library);
      await sut(testDir, const [
        RenovateUpgrade(
          manager: 'pub',
          depName: 'path',
          packageFile: 'packages/b/pubspec.yaml',
          currentValue: '^1.8.0',
          newValue: '^1.8.0 || ^1.9.0',
        ),
      ]);

      final pubspec = testFile('packages/b/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('dependencies:\ndev_dependencies:\n'));
      expect(pubspec, contains('  path: ">=1.8.0 <2.0.0"\n'));
    }, timeout: const Timeout(Duration(minutes: 5)));

    group('mergeWidenedConstraint', () {
      test('merges caret ranges into one range', () {
        expect(
          PostUpgrade.mergeWidenedConstraint('^13.3.0 || ^14.0.0'),
          VersionConstraint.parse('>=13.3.0 <15.0.0'),
        );
        expect(
          PostUpgrade.mergeWidenedConstraint('^13.3.0 || ^14.0.0').toString(),
          '>=13.3.0 <15.0.0',
        );
      });

      test('covers gaps and keeps unbounded ends', () {
        expect(
          PostUpgrade.mergeWidenedConstraint('>=1.0.0 <2.0.0 || >=3.0.0')
              .toString(),
          '>=1.0.0',
        );
        expect(
          PostUpgrade.mergeWidenedConstraint('^2.0.0 || <1.5.0').toString(),
          '<3.0.0',
        );
      });

      test('throws on unsupported parts', () {
        expect(
          () => PostUpgrade.mergeWidenedConstraint('^1.0.0 || foo'),
          throwsFormatException,
        );
      });
    });
  });
}
