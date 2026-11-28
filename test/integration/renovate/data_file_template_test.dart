@TestOn('dart-vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/renovate/models/message_template.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:dart_test_tools/src/renovate/renovate_preset.dart';
import 'package:dart_test_tools/src/renovate/upgrade_data.dart';
import 'package:dart_test_tools/src/test/test_data.dart';
import 'package:path/path.dart';
import 'package:test/scaffolding.dart';

import '../_support/run_bin.dart';

void main() {
  group('dataFileTemplate', () {
    late Directory testDir;

    setUpAll(() {
      if (!File('tool/renovate/node_modules/renovate/package.json')
          .existsSync()) {
        throw StateError(
          'Renovate is not installed: run '
          '`tool/setup_integration.sh`',
        );
      }
    });

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      addTearDown(() => testDir.delete(recursive: true));
    });

    String dataFileTemplate(RenovatePreset preset) {
      final json = jsonDecode(
        File('renovate/${preset.name}.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      return (json['postUpgradeTasks']
              as Map<String, dynamic>)['dataFileTemplate']
          as String;
    }

    Future<List<RenovateUpgrade>> render(
      RenovatePreset preset,
      List<Map<String, String>> upgrades,
    ) async {
      final inputFile = File(join(testDir.path, 'input.json'));
      final dataFile = File(join(testDir.path, 'data.json'));
      await inputFile.writeAsString(
        json.encode({
          'template': dataFileTemplate(preset),
          'input': {'upgrades': upgrades},
        }),
      );

      final result = await Process.run('node', [
        absolute('tool', 'renovate', 'render_template.mjs'),
        inputFile.path,
        dataFile.path,
      ], runInShell: Platform.isWindows);
      check(result.exitCode, because: result.output).equals(0);

      return await UpgradeData.load(dataFile);
    }

    testData<RenovatePreset>(
      'sends all placeholder values unchanged',
      RenovatePreset.values,
      dataToString: (preset) => preset.name,
      (preset) async {
        final upgrade = {
          for (final name in MessageTemplate.placeholders.keys)
            name: '$name "quoted" \\back\\slash {{curly}} ümlaut',
        };

        final upgrades = await render(preset, [upgrade]);

        check(upgrades).length.equals(1);
        for (final MapEntry(key: name, value: valueOf)
            in MessageTemplate.placeholders.entries) {
          check(valueOf(upgrades.single), because: name).equals(upgrade[name]);
        }
      },
    );

    testData<RenovatePreset>(
      'sends missing and empty values as null',
      RenovatePreset.values,
      dataToString: (preset) => preset.name,
      (preset) async {
        final upgrades = await render(preset, [
          {
            'manager': 'regex',
            'depName': 'native-lib',
            'packageFile': 'version.txt',
            'newDigest': '',
          },
          {'manager': 'pub', 'depName': 'path', 'packageFile': 'pubspec.yaml'},
        ]);

        check(upgrades).deepEquals(const [
          RenovateUpgrade(
            manager: 'regex',
            depName: 'native-lib',
            packageFile: 'version.txt',
          ),
          RenovateUpgrade(
            manager: 'pub',
            depName: 'path',
            packageFile: 'pubspec.yaml',
          ),
        ]);
      },
    );
  });
}
