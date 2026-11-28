@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/pub/pub_wrapper.dart';
import 'package:dart_test_tools/src/renovate/models/bump_level.dart';
import 'package:dart_test_tools/src/test/test_data.dart';
import 'package:path/path.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('$PubWrapper', () {
    late Directory testDir;
    late PubWrapper sut;

    File testFile(String path) => File(join(testDir.path, path));

    Future<void> writeFile(String path, String content) =>
        testFile(path).writeAsString(content);

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      sut = PubWrapper(testDir, isFlutter: false);
    });

    tearDown(() => testDir.delete(recursive: true));

    group('isValid', () {
      test('is false without pubspec.yaml', () {
        check(sut.isValid).isFalse;
      });

      test('is true with pubspec.yaml', () async {
        await writeFile('pubspec.yaml', 'name: pkg\n');

        check(sut.isValid).isTrue;
      });
    });

    group('hasChangelog', () {
      test('is false without CHANGELOG.md', () {
        check(sut.hasChangelog).isFalse;
      });

      test('is true with CHANGELOG.md', () async {
        await writeFile('CHANGELOG.md', '# Changelog\n');

        check(sut.hasChangelog).isTrue;
      });
    });

    test('pubspec parses pubspec.yaml', () async {
      await writeFile('pubspec.yaml', 'name: pkg\nversion: 1.2.3\n');

      final pubspec = await sut.pubspec();

      check(pubspec)
        ..has('name', (p) => p.name).equals('pkg')
        ..has('version', (p) => p.version?.toString()).equals('1.2.3');
    });

    group('pubspecEdit', () {
      const pubspec = 'name: pkg\n# keep me\nversion: 1.0.0\n';

      test('writes the edits and keeps comments', () async {
        await writeFile('pubspec.yaml', pubspec);

        await sut.pubspecEdit((editor) => editor.update(['version'], '2.0.0'));

        check(testFile('pubspec.yaml').readAsStringSync())
            .equals('name: pkg\n# keep me\nversion: 2.0.0\n');
      });

      test('does not write without edits', () async {
        await writeFile('pubspec.yaml', pubspec);
        final modified = DateTime(2000);
        testFile('pubspec.yaml').setLastModifiedSync(modified);

        await sut.pubspecEdit((_) {});

        check(testFile('pubspec.yaml').lastModifiedSync()).equals(modified);
      });
    });

    group('renovateConfig', () {
      testData<(String, String)>(
        'uses defaults',
        const [
          ('without renovate section', ''),
          ('with a null renovate section', 'renovate:\n'),
          ('with an empty renovate section', 'renovate: {}\n'),
        ],
        dataToString: (d) => d.$1,
        (d) async {
          await writeFile('pubspec.yaml', 'name: pkg\n${d.$2}');

          final config = await sut.renovateConfig();

          check(config)
            ..has(
              'preBuildExtraManagers',
              (c) => c.preBuildExtraManagers.toList(),
            ).isEmpty
            ..has('preBuildCommand', (c) => c.preBuildCommand).isNull
            ..has('bumpRules', (c) => c.bumpRules).isEmpty;
        },
      );

      test('parses all keys', () async {
        await writeFile('pubspec.yaml', '''
name: pkg
renovate:
  pre_build_extra_managers: [npm, regex]
  pre_build_command: echo ok
  bump_rules:
    - manager: regex
      name: native-lib
      bump: minor
      message: Updated {{depName}}
''');

        final config = await sut.renovateConfig();

        check(config)
          ..has(
            'preBuildExtraManagers',
            (c) => c.preBuildExtraManagers.toList(),
          ).deepEquals(['npm', 'regex'])
          ..has('preBuildCommand', (c) => c.preBuildCommand).equals('echo ok')
          ..has(
            'bumpRules',
            (c) => c.bumpRules,
          ).single.has('bump', (r) => r.bump).equals(BumpLevel.minor);
      });

      test('accepts a single extra manager', () async {
        await writeFile(
          'pubspec.yaml',
          'name: pkg\nrenovate:\n  pre_build_extra_managers: regex\n',
        );

        final config = await sut.renovateConfig();

        check(config.preBuildExtraManagers.toList()).deepEquals(['regex']);
      });

      test('rejects unknown keys', () async {
        await writeFile(
          'pubspec.yaml',
          'name: pkg\nrenovate:\n  pre_build_comand: echo typo\n',
        );

        await check(sut.renovateConfig()).throws<Object>();
      });

      test('rejects a renovate section that is not a map', () async {
        await writeFile('pubspec.yaml', 'name: pkg\nrenovate: yes\n');

        await check(sut.renovateConfig()).throws<Exception>(
          .it()
            ..has(
              'message',
              (e) => e.toString(),
            ).contains('must be a map or null'),
        );
      });
    });

    group('analysisOptionsPlugins', () {
      test('is empty without analysis_options.yaml', () async {
        check(await sut.analysisOptionsPlugins()).isEmpty;
      });

      test('is empty without plugins', () async {
        await writeFile('analysis_options.yaml', 'include: x.yaml\n');

        check(await sut.analysisOptionsPlugins()).isEmpty;
      });

      test('returns plugins with version constraints only', () async {
        await writeFile('analysis_options.yaml', '''
plugins:
  versioned: ^1.2.0
  local:
    path: ../local
  disabled: false
''');

        check(await sut.analysisOptionsPlugins())
            .deepEquals({'versioned': '^1.2.0'});
      });
    });

    test('analysisOptionsEdit writes the edits', () async {
      await writeFile('analysis_options.yaml', 'plugins:\n  p: ^1.0.0\n');

      await sut.analysisOptionsEdit(
        (editor) => editor.update(['plugins', 'p'], '^2.0.0'),
      );

      check(testFile('analysis_options.yaml').readAsStringSync())
          .equals('plugins:\n  p: ^2.0.0\n');
    });
  });
}
