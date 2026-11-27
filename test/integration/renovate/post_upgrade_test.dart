@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/renovate/models/bump_level.dart';
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
          depName: 'dart',
          packageFile: 'packages/a/pubspec.yaml',
          currentValue: '^3.9.0',
          newValue: '^3.13.0',
        ),
      ]);

      expect(packageVersion('packages/a'), '2.0.1');
      expect(testFile('packages/a/CHANGELOG.md').existsSync(), isFalse);
    }, timeout: const Timeout(Duration(minutes: 5)));

    group('release decision', () {
      Future<void> expectUnchanged(
        PostUpgradeMode mode,
        RenovateUpgrade upgrade,
      ) async {
        final pubspecBefore = testFile('packages/b/pubspec.yaml')
            .readAsStringSync();
        final changelogBefore = testFile('packages/b/CHANGELOG.md')
            .readAsStringSync();

        await PostUpgrade(mode: mode)(testDir, [upgrade]);

        expect(
          testFile('packages/b/pubspec.yaml').readAsStringSync(),
          pubspecBefore,
        );
        expect(
          testFile('packages/b/CHANGELOG.md').readAsStringSync(),
          changelogBefore,
        );
      }

      Future<void> expectReleased(
        PostUpgradeMode mode,
        RenovateUpgrade upgrade,
      ) async {
        await PostUpgrade(mode: mode)(testDir, [upgrade]);

        expect(packageVersion('packages/b'), '1.0.1');
        final lines = changelogLines('packages/b');
        expect(lines, contains(startsWith('## 1.0.1 - ')));
        expect(lines.where((l) => l == '- Updated dependencies'), hasLength(1));
      }

      const withinBound = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'packages/b/pubspec.yaml',
        depType: 'dependencies',
        currentValue: '^1.8.0',
        newValue: '^1.9.0',
      );

      test(
        'library mode does not release upgrades within the upper bound',
        () => expectUnchanged(PostUpgradeMode.library, withinBound),
        timeout: const Timeout(Duration(minutes: 5)),
      );

      test(
        'library mode does not release dev dependencies '
        'with a new upper bound',
        () => expectUnchanged(
          PostUpgradeMode.library,
          const RenovateUpgrade(
            manager: 'pub',
            depName: 'test',
            packageFile: 'packages/b/pubspec.yaml',
            depType: 'dev_dependencies',
            currentValue: '^1.0.0',
            newValue: '^2.0.0',
          ),
        ),
        timeout: const Timeout(Duration(minutes: 5)),
      );

      test(
        'library mode releases dependencies with a new upper bound',
        () => expectReleased(
          PostUpgradeMode.library,
          const RenovateUpgrade(
            manager: 'pub',
            depName: 'path',
            packageFile: 'packages/b/pubspec.yaml',
            depType: 'dependencies',
            currentValue: '^0.9.0',
            newValue: '^1.9.0',
          ),
        ),
        timeout: const Timeout(Duration(minutes: 5)),
      );

      test(
        'application mode releases upgrades within the upper bound',
        () => expectReleased(PostUpgradeMode.application, withinBound),
        timeout: const Timeout(Duration(minutes: 5)),
      );
    });

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

      group('extra managers', () {
        const regexUpgrade = RenovateUpgrade(
          manager: 'regex',
          depName: 'flutter',
          packageFile: 'sbx/flutter/flutter.yaml',
          currentValue: '3.50.0',
          newValue: '3.51.0',
        );
        const npmUpgrade = RenovateUpgrade(
          manager: 'npm',
          depName: 'renovate',
          packageFile: 'tool/renovate/package.json',
          currentValue: '44.164.5',
          newValue: '44.170.0',
        );

        Future<void> setRenovateConfig(String extraManagers, String command) =>
            writeFile(
              'pubspec.yaml',
              '${testFile('pubspec.yaml').readAsStringSync()}'
                  'renovate:\n'
                  '  pre_build_extra_managers: $extraManagers\n'
                  '  pre_build_command: $command\n',
            );

        test(
          'run the command in the repository root without a release',
          () async {
            await setRenovateConfig('regex', 'echo ok > marker.txt');

            const sut = PostUpgrade(mode: PostUpgradeMode.library);
            await sut(testDir, const [regexUpgrade]);

            expect(testFile('marker.txt').readAsStringSync(), 'ok\n');
            expect(packageVersion('packages/b'), '1.0.0');
            expect(
              changelogLines('packages/b').where((l) => l.startsWith('## ')),
              hasLength(1),
            );
          },
          timeout: const Timeout(Duration(minutes: 5)),
        );

        test('can be given as a list', () async {
          await setRenovateConfig('[npm, regex]', 'echo ok > marker.txt');

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await sut(testDir, const [regexUpgrade]);

          expect(testFile('marker.txt').readAsStringSync(), 'ok\n');
        }, timeout: const Timeout(Duration(minutes: 5)));

        test('ignore managers that are not listed', () async {
          await setRenovateConfig('regex', 'echo ok > marker.txt');

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await sut(testDir, const [npmUpgrade]);

          expect(testFile('marker.txt').existsSync(), isFalse);
        }, timeout: const Timeout(Duration(minutes: 5)));

        test('only get dependencies in application mode', () async {
          Future<void> setPathConstraint(String from, String to) => writeFile(
            'packages/b/pubspec.yaml',
            testFile('packages/b/pubspec.yaml')
                .readAsStringSync()
                .replaceFirst('path: $from', 'path: $to'),
          );

          await setPathConstraint('^1.9.0', '1.8.0');
          await pubGet();
          await setPathConstraint('1.8.0', '^1.8.0');
          await setRenovateConfig('regex', 'echo ok > marker.txt');

          const sut = PostUpgrade(mode: PostUpgradeMode.application);
          await sut(testDir, const [regexUpgrade]);

          expect(testFile('marker.txt').readAsStringSync(), 'ok\n');
          expect(lockedVersion('path'), '1.8.0');
        }, timeout: const Timeout(Duration(minutes: 5)));

        test('fail if the command fails', () async {
          await setRenovateConfig('regex', 'exit 3');

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await expectLater(
            sut(testDir, const [regexUpgrade]),
            throwsException,
          );
        }, timeout: const Timeout(Duration(minutes: 5)));

        test('run the command once next to pub upgrades of the root', () async {
          await setRenovateConfig('regex', 'echo ok >> marker.txt');

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await sut(testDir, const [regexUpgrade, pathUpgrade]);

          expect(testFile('marker.txt').readAsStringSync(), 'ok\n');
          expect(packageVersion('packages/b'), '1.0.1');
        }, timeout: const Timeout(Duration(minutes: 5)));
      });

      test('rejects unknown renovate config keys', () async {
        await writeFile(
          'pubspec.yaml',
          '${testFile('pubspec.yaml').readAsStringSync()}'
              'renovate:\n'
              '  pre_build_comand: echo typo\n',
        );

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await expectLater(sut(testDir, const [pathUpgrade]), throwsA(anything));
      }, timeout: const Timeout(Duration(minutes: 5)));

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

    group('bump rules', () {
      const nativeUpgrade = RenovateUpgrade(
        manager: 'regex',
        depName: 'native-lib',
        packageFile: 'packages/b/lib/native/version.txt',
        currentValue: '1.0.21+202610010000',
        newValue: '1.0.22+202611181006',
        newVersion: '1.0.22',
        updateType: 'patch',
      );
      const nativeEntry = '- Updated native-lib to 1.0.22+202611181006';

      String rule({
        String manager = 'regex',
        String name = 'native-lib',
        String? updateTypes,
        String? bump,
        String message = 'Updated {{depName}} to {{newValue}}',
      }) =>
          '    - manager: $manager\n'
          '      name: $name\n'
          '${updateTypes != null ? '      update_types: $updateTypes\n' : ''}'
          '${bump != null ? '      bump: $bump\n' : ''}'
          '      message: "$message"\n';

      Future<void> setRules(
        List<String> rules, {
        String dir = '.',
        String extraConfig = '',
      }) {
        final path = join(dir, 'pubspec.yaml');
        return writeFile(
          path,
          '${testFile(path).readAsStringSync()}'
          'renovate:\n'
          '$extraConfig'
          '  bump_rules:\n'
          '${rules.join()}',
        );
      }

      Map<String, String> snapshot() => {
        for (final entity in testDir.listSync(recursive: true))
          if (entity is File &&
              !entity.path.contains('.dart_tool') &&
              !entity.path.endsWith('pubspec.lock'))
            entity.path: entity.readAsStringSync(),
      };

      Iterable<String> releases(String path) =>
          changelogLines(path).where((l) => l.startsWith('## '));

      /// The entries of the release [version] in the changelog of [path].
      List<String> entries(String path, String version) =>
          changelogLines(path)
              .skipWhile((l) => !l.startsWith('## $version - '))
              .skip(1)
              .takeWhile((l) => !l.startsWith('## '))
              .where((l) => l.startsWith('- '))
              .toList();

      for (final mode in PostUpgradeMode.values) {
        test('release a package for a matching non-pub upgrade in ${mode.name} '
            'mode', () async {
          await setRules([rule()]);

          await PostUpgrade(mode: mode)(testDir, const [nativeUpgrade]);

          expect(packageVersion('packages/b'), '1.0.1');
          expect(releases('packages/b'), hasLength(2));
          expect(entries('packages/b', '1.0.1'), [nativeEntry]);
        }, timeout: const Timeout(Duration(minutes: 5)));
      }

      for (final (bump, version) in [
        ('build', '1.0.0+1'),
        ('minor', '1.1.0'),
        ('breaking', '2.0.0'),
        ('major', '2.0.0'),
      ]) {
        test('$bump bump creates version $version', () async {
          await setRules([rule(bump: bump)]);

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await sut(testDir, const [nativeUpgrade]);

          expect(packageVersion('packages/b'), version);
          expect(
            releases('packages/b'),
            contains(startsWith('## $version - ')),
          );
          expect(entries('packages/b', version), [nativeEntry]);
        }, timeout: const Timeout(Duration(minutes: 5)));
      }

      test('biggest bump of rules and pub upgrades wins', () async {
        await setRules([rule(bump: 'minor')]);

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [
          nativeUpgrade,
          RenovateUpgrade(
            manager: 'pub',
            depName: 'dart',
            packageFile: 'packages/b/pubspec.yaml',
            currentValue: '^3.9.0',
            newValue: '^3.13.0',
          ),
        ]);

        expect(packageVersion('packages/b'), '1.1.0');
        expect(releases('packages/b'), hasLength(2));
        expect(entries('packages/b', '1.1.0'), [
          '- Updated min sdk version to ^3.13.0',
          nativeEntry,
          '- Updated dependencies',
        ]);
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('pub upgrades keep their patch bump next to a build bump', () async {
        await setRules([rule(bump: 'build')]);

        const sut = PostUpgrade(mode: PostUpgradeMode.application);
        await sut(testDir, const [
          nativeUpgrade,
          RenovateUpgrade(
            manager: 'pub',
            depName: 'path',
            packageFile: 'packages/b/pubspec.yaml',
          ),
        ]);

        expect(packageVersion('packages/b'), '1.0.1');
        expect(entries('packages/b', '1.0.1'), [
          nativeEntry,
          '- Updated dependencies',
        ]);
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('rules force a release of pub upgrades in library mode', () async {
        await setRules([rule(bump: 'build')]);

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [
          nativeUpgrade,
          RenovateUpgrade(
            manager: 'pub',
            depName: 'path',
            packageFile: 'packages/b/pubspec.yaml',
            depType: 'dependencies',
            currentValue: '^1.8.0',
            newValue: '^1.9.0',
          ),
        ]);

        expect(packageVersion('packages/b'), '1.0.0+1');
        expect(entries('packages/b', '1.0.0+1'), [
          nativeEntry,
          '- Updated dependencies',
        ]);
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('rules can match pub upgrades', () async {
        await setRules([
          rule(
            manager: 'pub',
            name: 'path',
            bump: 'minor',
            message: 'Bundled path {{newValue}}',
          ),
        ]);

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [
          RenovateUpgrade(
            manager: 'pub',
            depName: 'path',
            packageFile: 'packages/b/pubspec.yaml',
            depType: 'dependencies',
            currentValue: '^1.8.0',
            newValue: '^1.9.0',
          ),
        ]);

        expect(packageVersion('packages/b'), '1.1.0');
        expect(entries('packages/b', '1.1.0'), [
          '- Bundled path ^1.9.0',
          '- Updated dependencies',
        ]);
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('grouped upgrades create one entry per distinct message', () async {
        await setRules([
          rule(name: '[native-lib, other-lib]'),
          rule(
            updateTypes: 'digest',
            bump: 'build',
            message: 'Rebuilt {{depName}} ({{newDigestShort}})',
          ),
        ]);

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, [
          nativeUpgrade,
          nativeUpgrade.copyWith(packageFile: 'packages/b/lib/native/x.cmake'),
          nativeUpgrade.copyWith(
            depName: 'other-lib',
            newValue: '2.0.0',
            packageFile: 'packages/b/native/other.txt',
          ),
        ]);

        expect(packageVersion('packages/b'), '1.0.1');
        expect(releases('packages/b'), hasLength(2));
        expect(entries('packages/b', '1.0.1'), [
          nativeEntry,
          '- Updated other-lib to 2.0.0',
        ]);
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('first matching rule wins', () async {
        await setRules([
          rule(
            updateTypes: '[digest, pinDigest]',
            bump: 'build',
            message: 'Rebuilt {{depName}} ({{newDigestShort}})',
          ),
          rule(bump: 'major', message: 'Catch all'),
        ]);

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [
          RenovateUpgrade(
            manager: 'regex',
            depName: 'native-lib',
            packageFile: 'packages/b/lib/native/version.txt',
            currentValue: '1.0.21',
            newValue: '1.0.21',
            newDigestShort: 'abc1234',
            updateType: 'digest',
          ),
        ]);

        expect(packageVersion('packages/b'), '1.0.0+1');
        expect(
          entries('packages/b', '1.0.0+1').first,
          '- Rebuilt native-lib (abc1234)',
        );
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('rules of member packages are ignored', () async {
        await setRules([rule(bump: 'minor')], dir: 'packages/b');
        final before = snapshot();

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [nativeUpgrade]);

        expect(snapshot(), before);
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('do not run the pre-build command of other managers', () async {
        await setRules([
          rule(),
        ], extraConfig: '  pre_build_command: echo ok > marker.txt\n');

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [nativeUpgrade]);

        expect(testFile('marker.txt').existsSync(), isFalse);
        expect(packageVersion('packages/b'), '1.0.1');
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('run the pre-build command of extra managers first', () async {
        await setRules(
          [rule(message: 'Native {{newVersion}}')],
          extraConfig:
              '  pre_build_extra_managers: regex\n'
              '  pre_build_command: '
              'grep -c Native packages/b/CHANGELOG.md > marker.txt || true\n',
        );

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, const [nativeUpgrade]);

        expect(testFile('marker.txt').readAsStringSync(), '0\n');
        expect(entries('packages/b', '1.0.1').first, '- Native 1.0.22');
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('missing placeholder values fail before changing files', () async {
        await setRules([rule(message: 'Digest {{newDigest}}')]);
        final before = snapshot();

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await expectLater(
          sut(testDir, const [nativeUpgrade]),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('newDigest') &&
                  e.toString().contains('regex/native-lib'),
            ),
          ),
        );

        expect(snapshot(), before);
      }, timeout: const Timeout(Duration(minutes: 5)));

      for (final (description, upgrade) in [
        ('upgrades matching no rule', nativeUpgrade.copyWith(depName: 'typo')),
        (
          'upgrades of packages without version or changelog',
          nativeUpgrade.copyWith(packageFile: 'packages/a/native/version.txt'),
        ),
        (
          'upgrades of the workspace root',
          nativeUpgrade.copyWith(packageFile: 'tool/native/version.txt'),
        ),
      ]) {
        test('$description change nothing', () async {
          await setRules([rule()]);
          final before = snapshot();

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await sut(testDir, [upgrade]);

          expect(snapshot(), before);
        }, timeout: const Timeout(Duration(minutes: 5)));
      }

      test('unrelated pubspecs do not take over non-pub upgrades', () async {
        await setRules([rule()]);
        await writeFile('packages/b/tool/native/pubspec.yaml', '''
name: native
version: 1.0.0
publish_to: none
environment:
  sdk: ^3.9.0
''');

        const sut = PostUpgrade(mode: PostUpgradeMode.library);
        await sut(testDir, [
          nativeUpgrade.copyWith(
            packageFile: 'packages/b/tool/native/version.txt',
          ),
        ]);

        expect(packageVersion('packages/b'), '1.0.1');
        expect(entries('packages/b', '1.0.1'), [nativeEntry]);
        expect(packageVersion('packages/b/tool/native'), '1.0.0');
      }, timeout: const Timeout(Duration(minutes: 5)));

      group('attributes upgrades', () {
        const pathUpgrade = RenovateUpgrade(
          manager: 'pub',
          depName: 'path',
          packageFile: 'packages/b/pubspec.yaml',
        );

        void expectReleased() {
          expect(packageVersion('packages/b'), '1.0.1');
          expect(entries('packages/b', '1.0.1'), [
            nativeEntry,
            '- Updated dependencies',
          ]);
        }

        test('through a symlinked repository root', () async {
          await setRules([rule()]);
          final linkDir = await Directory.systemTemp.createTemp();
          addTearDown(() => linkDir.delete(recursive: true));
          final link = await Link(join(linkDir.path, 'repo'))
              .create(testDir.path);

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await sut(Directory(link.path), const [nativeUpgrade, pathUpgrade]);

          expectReleased();
        }, timeout: const Timeout(Duration(minutes: 5)));

        test('with non-normalized package files', () async {
          await setRules([rule()]);

          const sut = PostUpgrade(mode: PostUpgradeMode.library);
          await sut(testDir, [
            nativeUpgrade.copyWith(
              packageFile: './packages/b/lib/../lib/native/version.txt',
            ),
            pathUpgrade.copyWith(packageFile: './packages//b/pubspec.yaml'),
          ]);

          expectReleased();
        }, timeout: const Timeout(Duration(minutes: 5)));
      });
    });

    group('releaseLevel', () {
      const withinBound = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'pubspec.yaml',
        depType: 'dependencies',
        currentValue: '^1.2.0',
        newValue: '^1.3.0',
      );
      const newBound = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'pubspec.yaml',
        depType: 'dependencies',
        currentValue: '^1.2.0',
        newValue: '^2.0.0',
      );

      test('is null without upgrades and rules', () {
        for (final mode in PostUpgradeMode.values) {
          expect(PostUpgrade.releaseLevel(mode, const [], const []), isNull);
        }
      });

      test('is patch for pub upgrades in application mode', () {
        expect(
          PostUpgrade.releaseLevel(.application, const [withinBound], const []),
          BumpLevel.patch,
        );
      });

      test('is patch for pub upgrades with a new bound in library mode', () {
        expect(
          PostUpgrade.releaseLevel(.library, const [newBound], const []),
          BumpLevel.patch,
        );
      });

      test('is null for pub upgrades within bounds in library mode', () {
        expect(
          PostUpgrade.releaseLevel(.library, const [withinBound], const []),
          isNull,
        );
      });

      test('is the biggest rule level without pub upgrades', () {
        expect(
          PostUpgrade.releaseLevel(.library, const [], const [
            BumpLevel.build,
            BumpLevel.breaking,
            BumpLevel.minor,
          ]),
          BumpLevel.breaking,
        );
      });

      test('is the biggest of pub and rule levels', () {
        expect(
          PostUpgrade.releaseLevel(
            .library,
            const [newBound],
            const [BumpLevel.build],
          ),
          BumpLevel.patch,
        );
        expect(
          PostUpgrade.releaseLevel(
            .application,
            const [withinBound],
            const [BumpLevel.major],
          ),
          BumpLevel.major,
        );
        expect(
          PostUpgrade.releaseLevel(
            .library,
            const [withinBound],
            const [BumpLevel.build],
          ),
          BumpLevel.build,
        );
      });
    });

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

    group('changesUpperBound', () {
      test('keeps the bound for a caret minor bump', () {
        expect(PostUpgrade.changesUpperBound('^1.2.0', '^1.3.0'), isFalse);
      });

      test('keeps the bound for an equivalent range', () {
        expect(
          PostUpgrade.changesUpperBound('^1.8.0', '>=1.9.0 <2.0.0'),
          isFalse,
        );
      });

      test('keeps the bound of a raised lower range bound', () {
        expect(
          PostUpgrade.changesUpperBound('>=1.0.0 <3.0.0', '>=2.0.0 <3.0.0'),
          isFalse,
        );
      });

      test('detects a major bump', () {
        expect(PostUpgrade.changesUpperBound('^1.2.0', '^2.0.0'), isTrue);
      });

      test('detects a 0.x minor bump', () {
        expect(PostUpgrade.changesUpperBound('^0.14.0', '^0.15.0'), isTrue);
      });

      test('detects a widened constraint', () {
        expect(
          PostUpgrade.changesUpperBound('^13.3.0', '^13.3.0 || ^14.0.0'),
          isTrue,
        );
      });

      test('detects a bounded constraint becoming unbounded', () {
        expect(PostUpgrade.changesUpperBound('^1.0.0', '>=1.0.0'), isTrue);
      });

      test('detects a pinned version bump', () {
        expect(PostUpgrade.changesUpperBound('1.2.3', '1.2.4'), isTrue);
      });

      test('bumps if a value is missing', () {
        expect(PostUpgrade.changesUpperBound(null, '^1.0.0'), isTrue);
        expect(PostUpgrade.changesUpperBound('^1.0.0', null), isTrue);
      });

      test('bumps for unparsable values', () {
        expect(PostUpgrade.changesUpperBound('main', 'v2'), isTrue);
      });
    });

    group('requiresVersionBump', () {
      RenovateUpgrade dep(String? depType, String current, String next) =>
          RenovateUpgrade(
            manager: 'pub',
            depName: 'pkg',
            packageFile: 'pubspec.yaml',
            depType: depType,
            currentValue: current,
            newValue: next,
          );

      test('is false without upgrades', () {
        expect(PostUpgrade.requiresVersionBump(const []), isFalse);
      });

      test('is true for sdk upgrades', () {
        for (final sdk in const ['dart', 'flutter']) {
          expect(
            PostUpgrade.requiresVersionBump([
              RenovateUpgrade(
                manager: 'pub',
                depName: sdk,
                packageFile: 'pubspec.yaml',
                currentValue: '^3.9.0',
                newValue: '^3.10.0',
              ),
            ]),
            isTrue,
            reason: sdk,
          );
        }
      });

      test('is false for dependencies within their bound', () {
        expect(
          PostUpgrade.requiresVersionBump([
            dep('dependencies', '^1.2.0', '^1.3.0'),
          ]),
          isFalse,
        );
      });

      test('is true for dependencies with a new bound', () {
        expect(
          PostUpgrade.requiresVersionBump([
            dep('dependencies', '^1.2.0', '^2.0.0'),
          ]),
          isTrue,
        );
      });

      test('ignores dev dependencies', () {
        expect(
          PostUpgrade.requiresVersionBump([
            dep('dev_dependencies', '^1.2.0', '^2.0.0'),
          ]),
          isFalse,
        );
      });

      test('treats a missing depType as dependency', () {
        expect(
          PostUpgrade.requiresVersionBump([dep(null, '^1.2.0', '^2.0.0')]),
          isTrue,
        );
      });

      test('is true if any upgrade requires it', () {
        expect(
          PostUpgrade.requiresVersionBump([
            dep('dependencies', '^1.2.0', '^1.3.0'),
            dep('dev_dependencies', '^1.0.0', '^2.0.0'),
            dep('dependencies', '^0.1.0', '^0.2.0'),
          ]),
          isTrue,
        );
      });
    });
  });
}
