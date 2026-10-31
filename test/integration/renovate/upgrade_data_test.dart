@TestOn('dart-vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:dart_test_tools/src/renovate/upgrade_data.dart';
import 'package:test/test.dart';

void main() {
  group('$UpgradeData', () {
    late Directory testDir;
    late File dataFile;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      dataFile = File.fromUri(testDir.uri.resolve('data.json'));
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    Future<void> writeData(List<Map<String, dynamic>> data) =>
        dataFile.writeAsString(json.encode(data));

    test('load parses all fields', () async {
      await writeData([
        {
          'manager': 'pub',
          'depName': 'dart',
          'packageFile': 'packages/pure/pubspec.yaml',
          'depType': '',
          'currentValue': '^3.6.0',
          'newValue': '^3.13.0',
          'updateType': 'minor',
        },
        {
          'manager': 'pub',
          'depName': 'collection',
          'packageFile': 'pubspec.yaml',
          'depType': 'dependencies',
          'currentValue': '^1.18.0',
          'newValue': '^1.19.1',
          'updateType': 'minor',
        },
      ]);

      final result = await UpgradeData.load(dataFile);

      expect(result, [
        const RenovateUpgrade(
          manager: 'pub',
          depName: 'dart',
          packageFile: 'packages/pure/pubspec.yaml',
          currentValue: '^3.6.0',
          newValue: '^3.13.0',
          updateType: 'minor',
        ),
        const RenovateUpgrade(
          manager: 'pub',
          depName: 'collection',
          packageFile: 'pubspec.yaml',
          depType: 'dependencies',
          currentValue: '^1.18.0',
          newValue: '^1.19.1',
          updateType: 'minor',
        ),
      ]);
    });

    test('empty strings become null', () async {
      await writeData([
        {
          'manager': 'pub',
          'depName': 'flutter',
          'packageFile': 'pubspec.yaml',
          'depType': '',
          'currentValue': '',
          'newValue': '',
          'updateType': '',
        },
      ]);

      final result = await UpgradeData.load(dataFile);

      expect(result, hasLength(1));
      expect(result.single.depType, isNull);
      expect(result.single.currentValue, isNull);
      expect(result.single.newValue, isNull);
      expect(result.single.updateType, isNull);
    });

    test('load accepts missing optional fields', () async {
      await writeData([
        {'manager': 'pub', 'depName': 'path', 'packageFile': 'pubspec.yaml'},
      ]);

      final result = await UpgradeData.load(dataFile);

      expect(result, [
        const RenovateUpgrade(
          manager: 'pub',
          depName: 'path',
          packageFile: 'pubspec.yaml',
        ),
      ]);
    });

    test('load parses entries of other managers', () async {
      await writeData([
        {
          'manager': 'npm',
          'depName': 'renovate',
          'packageFile': 'tool/renovate/package.json',
          'depType': 'dependencies',
          'currentValue': '44.164.5',
          'newValue': '44.170.0',
          'updateType': 'minor',
        },
      ]);

      final result = await UpgradeData.load(dataFile);

      expect(result, [
        const RenovateUpgrade(
          manager: 'npm',
          depName: 'renovate',
          packageFile: 'tool/renovate/package.json',
          depType: 'dependencies',
          currentValue: '44.164.5',
          newValue: '44.170.0',
          updateType: 'minor',
        ),
      ]);
    });

    test('load accepts an empty list', () async {
      await writeData([]);

      final result = await UpgradeData.load(dataFile);

      expect(result, isEmpty);
    });

    test('fromEnvironment loads the file named by the env var', () async {
      await writeData([
        {'manager': 'pub', 'depName': 'path', 'packageFile': 'pubspec.yaml'},
      ]);

      final result = await UpgradeData.fromEnvironment({
        UpgradeData.dataFileEnvVar: dataFile.path,
      });

      expect(result, [
        const RenovateUpgrade(
          manager: 'pub',
          depName: 'path',
          packageFile: 'pubspec.yaml',
        ),
      ]);
    });

    test('fromEnvironment throws StateError without env var', () {
      expect(() => UpgradeData.fromEnvironment({}), throwsA(isA<StateError>()));
    });
  });

  group('$RenovateUpgrade', () {
    test('isSdkUpgrade and sdkKey for dart', () {
      const sut = RenovateUpgrade(
        manager: 'pub',
        depName: 'dart',
        packageFile: 'pubspec.yaml',
      );

      expect(sut.isSdkUpgrade, isTrue);
      expect(sut.sdkKey, 'sdk');
    });

    test('isSdkUpgrade and sdkKey for flutter', () {
      const sut = RenovateUpgrade(
        manager: 'pub',
        depName: 'flutter',
        packageFile: 'pubspec.yaml',
      );

      expect(sut.isSdkUpgrade, isTrue);
      expect(sut.sdkKey, 'flutter');
    });

    test('isSdkUpgrade and sdkKey for other packages', () {
      const sut = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'pubspec.yaml',
      );

      expect(sut.isSdkUpgrade, isFalse);
      expect(() => sut.sdkKey, throwsA(isA<StateError>()));
    });
  });
}
