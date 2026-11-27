@TestOn('dart-vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/renovate/upgrade_data.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/scaffolding.dart';
import 'package:yaml/yaml.dart';

import '../_support/run_bin.dart';

void main() {
  group('renovate_post_upgrade', () {
    final postUpgradeBin = BinRunner('renovate_post_upgrade');
    late Directory testDir;

    File testFile(String path) => File(join(testDir.path, path));

    Future<void> writeFile(String path, String content) async {
      final file = testFile(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> appendFile(String path, String content) =>
        testFile(path).writeAsString(content, mode: FileMode.append);

    Future<void> replaceInFile(String path, String from, String to) =>
        writeFile(
          path,
          testFile(path).readAsStringSync().replaceFirst(from, to),
        );

    Future<void> pubGet() async {
      final result = await Process.run(Platform.resolvedExecutable, const [
        'pub',
        'get',
      ], workingDirectory: testDir.path);
      check(result.exitCode, because: result.output).equals(0);
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

    /// The entries of the release [version] in the changelog of [path].
    List<String> entries(String path, String version) =>
        testFile(join(path, 'CHANGELOG.md'))
            .readAsLinesSync()
            .skipWhile((l) => !l.startsWith('## $version - '))
            .skip(1)
            .takeWhile((l) => !l.startsWith('## '))
            .where((l) => l.startsWith('- '))
            .toList();

    /// Runs the post upgrade command for the renovate [upgrades] in [mode],
    /// like renovate does.
    Future<ProcessResult> postUpgrade(
      String? mode,
      List<Map<String, String>> upgrades,
    ) async {
      final dataFile = File('${testDir.path}.json');
      addTearDown(() async {
        if (dataFile.existsSync()) {
          await dataFile.delete();
        }
      });
      await dataFile.writeAsString(json.encode(upgrades));
      return await postUpgradeBin(
        [
          if (mode != null) ...['--mode', mode],
        ],
        workingDirectory: testDir,
        environment: {UpgradeData.dataFileEnvVar: dataFile.path},
      );
    }

    Future<void> expectSuccess(
      String mode,
      List<Map<String, String>> upgrades,
    ) async {
      final result = await postUpgrade(mode, upgrades);
      check(result.exitCode, because: result.output).equals(0);
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

    test('fails without a mode', () async {
      final result = await postUpgrade(null, const []);

      check(result.exitCode).equals(1);
      check(result.stderr).isA<String>().contains('Option mode is mandatory.');
    });

    test('regenerates the lockfile in application mode', () async {
      await replaceInFile(
        'packages/b/pubspec.yaml',
        'path: ^1.9.0',
        'path: 1.8.0',
      );
      await pubGet();
      check(lockedVersion('path')).equals('1.8.0');
      await replaceInFile(
        'packages/b/pubspec.yaml',
        'path: 1.8.0',
        'path: ^1.9.0',
      );

      await expectSuccess('application', const [
        {
          'manager': 'pub',
          'depName': 'path',
          'packageFile': 'packages/b/pubspec.yaml',
          'depType': 'dependencies',
          'currentValue': '1.8.0',
          'newValue': '^1.9.0',
        },
      ]);

      check(lockedVersion('path')).startsWith('1.9.');
      check(packageVersion('packages/b')).equals('1.0.1');
      check(entries('packages/b', '1.0.1'))
          .deepEquals(['- Updated dependencies']);
    });

    test(
      'runs build_runner and releases sdk upgrades in library mode',
      () async {
        await expectSuccess('library', const [
          {
            'manager': 'pub',
            'depName': 'dart',
            'packageFile': 'packages/a/pubspec.yaml',
            'currentValue': '^3.9.0',
            'newValue': '^3.13.0',
          },
          {
            'manager': 'pub',
            'depName': 'dart',
            'packageFile': 'packages/b/pubspec.yaml',
            'currentValue': '^3.9.0',
            'newValue': '^3.13.0',
          },
        ]);

        check(Directory(join(testDir.path, '.dart_tool', 'build')).existsSync())
            .isTrue;
        check(packageVersion('packages/a')).isNull;
        check(testFile('packages/a/CHANGELOG.md').existsSync()).isFalse;
        check(packageVersion('packages/b')).equals('1.0.1');
        check(entries('packages/b', '1.0.1')).deepEquals([
          '- Updated min sdk version to ^3.13.0',
          '- Updated dependencies',
        ]);
      },
    );

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
''');

      await expectSuccess('library', const [
        {
          'manager': 'pub',
          'depName': 'path',
          'packageFile': 'packages/b/pubspec.yaml',
          'depType': 'dependencies',
          'currentValue': '^1.8.0',
          'newValue': '^1.8.0 || ^1.9.0',
        },
      ]);

      check(testFile('packages/b/pubspec.yaml').readAsStringSync())
          .contains('  path: ">=1.8.0 <2.0.0"\n');
    });

    group('with a renovate config', () {
      test('runs the pre-build command and releases bump rule '
          'matches', () async {
        await appendFile('pubspec.yaml', r'''
renovate:
  pre_build_extra_managers: regex
  pre_build_command: |
    mkdir -p out
    cd out
    greeting=hello
    echo "$greeting" > first.txt
    grep -c Native ../packages/b/CHANGELOG.md >> first.txt || true
  bump_rules:
    - manager: regex
      name: native-lib
      bump: minor
      message: Native {{newVersion}}
''');

        await expectSuccess('library', const [
          {
            'manager': 'regex',
            'depName': 'native-lib',
            'packageFile': 'packages/b/lib/native/version.txt',
            'currentValue': '1.0.21+202610010000',
            'newValue': '1.0.22+202611181006',
            'newVersion': '1.0.22',
            'updateType': 'patch',
          },
        ]);

        check(testFile('out/first.txt').readAsStringSync())
            .equals('hello\n0\n');
        check(packageVersion('packages/b')).equals('1.1.0');
        check(entries('packages/b', '1.1.0')).deepEquals(['- Native 1.0.22']);
      });

      test('runs the pre-build command before build_runner', () async {
        // The builder of a imports a library with a missing part, so
        // build_runner cannot compile its build script until the pre-build
        // command created the part.
        await replaceInFile(
          'packages/a/pubspec.yaml',
          'dev_dependencies:',
          'dependencies:\n  build: ^4.0.0\ndev_dependencies:',
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
        const upgrades = [
          {
            'manager': 'pub',
            'depName': 'path',
            'packageFile': 'packages/b/pubspec.yaml',
          },
        ];

        final failed = await postUpgrade('library', upgrades);
        check(failed.exitCode, because: failed.output).not(.it()..equals(0));

        await appendFile(
          'pubspec.yaml',
          'renovate:\n'
              '  pre_build_command: '
              'cp packages/a/builder.g.dart.in packages/a/lib/builder.g.dart\n',
        );
        await expectSuccess('library', upgrades);

        check(testFile('packages/a/lib/builder.g.dart').existsSync()).isTrue;
      }, timeout: const Timeout(Duration(minutes: 10)));
    }, testOn: 'posix');
  });
}
