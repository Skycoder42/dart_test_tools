@TestOn('dart-vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/src/renovate/models/message_template.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:dart_test_tools/src/renovate/renovate_preset.dart';
import 'package:path/path.dart' show join;
import 'package:test/test.dart';

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
      expect(RenovatePreset.library.flutterCompat, isTrue);
      expect(RenovatePreset.application.flutterCompat, isFalse);
    });

    test('only the application preset offers unresolvable breaking '
        'updates', () {
      expect(RenovatePreset.library.offerBreaking, isFalse);
      expect(RenovatePreset.application.offerBreaking, isTrue);
    });

    group('detect', () {
      for (final preset in RenovatePreset.values) {
        test('detects the ${preset.name} preset', () async {
          await writeFile('renovate.json', '''
{
  "\$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>Skycoder42/dart_test_tools//renovate/${preset.name}"]
}
''');

          expect(await RenovatePreset.detect(testDir), preset);
        });
      }

      test('detects a pinned preset in a json5 file under .github', () async {
        await writeFile('.github/renovate.json5', '''
{
  // pinned to a tag
  extends: ['github>Skycoder42/dart_test_tools//renovate/library#v8.1.3'],
}
''');

        expect(await RenovatePreset.detect(testDir), RenovatePreset.library);
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

        expect(
          await RenovatePreset.detect(testDir),
          RenovatePreset.application,
        );
      });

      test('throws without a config file', () {
        expect(
          () => RenovatePreset.detect(testDir),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws if no preset is extended', () async {
        await writeFile('renovate.json', '{"extends": ["config:recommended"]}');

        expect(
          () => RenovatePreset.detect(testDir),
          throwsA(isA<FormatException>()),
        );
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

        expect(
          () => RenovatePreset.detect(testDir),
          throwsA(isA<FormatException>()),
        );
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
        expect(dataFileTemplate('library'), dataFileTemplate('application'));
      });

      test('send all fields of $RenovateUpgrade as JSON', () {
        final template = dataFileTemplate('library');
        final fields = [
          'manager',
          'depName',
          'packageFile',
          ...MessageTemplate.placeholders.keys,
        ];
        expect(template, startsWith('[{{#each upgrades}}{{{toJSON (toObject'));
        for (final field in fields.toSet()) {
          expect(
            template,
            matches(RegExp('"$field" $field[ )]')),
            reason: field,
          );
        }
      });
    });
  });
}
