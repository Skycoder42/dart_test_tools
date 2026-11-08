@TestOn('dart-vm')
library;

import 'dart:io';

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
  });
}
