@TestOn('dart-vm')
library;

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('$RenovateUpgrade', () {
    test('isSdkUpgrade and sdkKey for dart', () {
      const sut = RenovateUpgrade(
        manager: 'pub',
        depName: 'dart',
        packageFile: 'pubspec.yaml',
      );

      check(sut.isSdkUpgrade).isTrue;
      check(sut.sdkKey).equals('sdk');
    });

    test('isSdkUpgrade and sdkKey for flutter', () {
      const sut = RenovateUpgrade(
        manager: 'pub',
        depName: 'flutter',
        packageFile: 'pubspec.yaml',
      );

      check(sut.isSdkUpgrade).isTrue;
      check(sut.sdkKey).equals('flutter');
    });

    test('isSdkUpgrade and sdkKey for other packages', () {
      const sut = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'pubspec.yaml',
      );

      check(sut.isSdkUpgrade).isFalse;
      check(() => sut.sdkKey).throws<StateError>();
    });
  });
}
