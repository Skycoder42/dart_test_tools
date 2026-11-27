@TestOn('dart-vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/renovate/models/message_template.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:dart_test_tools/src/renovate/renovate_preset.dart';
import 'package:dart_test_tools/src/test/test_data.dart';
import 'package:path/path.dart' show join;
import 'package:test/scaffolding.dart';

void main() {
  group('$RenovatePreset', () {
    late Directory testDir;

    Future<void> writeFile(String path, String content) async {
      final file = File(join(testDir.path, path));
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test('only the library preset is flutter compatible', () {
      check(RenovatePreset.library.flutterCompat).isTrue;
      check(RenovatePreset.application.flutterCompat).isFalse;
    });

    test('only the application preset offers unresolvable breaking '
        'updates', () {
      check(RenovatePreset.library.offerBreaking).isFalse;
      check(RenovatePreset.application.offerBreaking).isTrue;
    });

    group('detect', () {
      testData<RenovatePreset>(
        'detects the preset',
        RenovatePreset.values,
        dataToString: (preset) => preset.name,
        (preset) async {
          await writeFile('renovate.json', '''
{
  "\$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>Skycoder42/dart_test_tools//renovate/${preset.name}"]
}
''');

          check(await RenovatePreset.detect(testDir)).equals(preset);
        },
      );

      test('detects a pinned preset in a json5 file under .github', () async {
        await writeFile('.github/renovate.json5', '''
{
  // pinned to a tag
  extends: ['github>Skycoder42/dart_test_tools//renovate/library#v8.1.3'],
}
''');

        check(await RenovatePreset.detect(testDir))
            .equals(RenovatePreset.library);
      });

      test('uses the first config file in renovate search order', () async {
        await writeFile(
          'renovate.json',
          '{"extends": ["github>Skycoder42/dart_test_tools//renovate/application"]}',
        );
        await writeFile(
          '.renovaterc',
          '{"extends": ["github>Skycoder42/dart_test_tools//renovate/library"]}',
        );

        check(await RenovatePreset.detect(testDir))
            .equals(RenovatePreset.application);
      });

      test('throws without a config file', () async {
        await check(RenovatePreset.detect(testDir)).throws<FormatException>();
      });

      test('throws if no preset is extended', () async {
        await writeFile('renovate.json', '{"extends": ["config:recommended"]}');

        await check(RenovatePreset.detect(testDir)).throws<FormatException>();
      });

      test('throws if both presets are extended', () async {
        await writeFile('renovate.json', '''
{
  "extends": [
    "github>Skycoder42/dart_test_tools//renovate/library",
    "github>Skycoder42/dart_test_tools//renovate/application"
  ]
}
''');

        await check(RenovatePreset.detect(testDir)).throws<FormatException>();
      });
    });

    group('presets', () {
      Map<String, dynamic> readPreset(String name) =>
          json.decode(File('renovate/$name.json').readAsStringSync())
              as Map<String, dynamic>;

      String dataFileTemplate(String name) =>
          (readPreset(name)['postUpgradeTasks']
                  as Map<String, dynamic>)['dataFileTemplate']
              as String;

      test('share the same data file template', () {
        check(dataFileTemplate('library'))
            .equals(dataFileTemplate('application'));
      });

      test('send all fields of $RenovateUpgrade as JSON', () {
        final template = dataFileTemplate('library');
        final fields = [
          'manager',
          'depName',
          'packageFile',
          ...MessageTemplate.placeholders.keys,
        ];
        check(template).startsWith('[{{#each upgrades}}{{{toJSON (toObject');
        for (final field in fields.toSet()) {
          check(
            template,
            because: field,
          ).matchesPattern(RegExp('"$field" $field[ )]'));
        }
      });
    });
  });
}
