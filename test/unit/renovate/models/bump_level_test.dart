@TestOn('dart-vm')
library;

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/renovate/models/bump_level.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('$BumpLevel', () {
    test('is ordered by bump size', () {
      check(BumpLevel.values).deepEquals([
        BumpLevel.build,
        BumpLevel.patch,
        BumpLevel.minor,
        BumpLevel.breaking,
        BumpLevel.major,
      ]);
    });

    test('maxOf returns the biggest level', () {
      check(
        BumpLevel.maxOf([BumpLevel.patch, BumpLevel.breaking, BumpLevel.minor]),
      ).equals(BumpLevel.breaking);
      check(BumpLevel.maxOf([BumpLevel.major, BumpLevel.breaking]))
          .equals(BumpLevel.major);
      check(BumpLevel.maxOf([BumpLevel.build])).equals(BumpLevel.build);
    });

    test('maxOf ignores null and returns null for no levels', () {
      check(BumpLevel.maxOf([null, BumpLevel.build, null]))
          .equals(BumpLevel.build);
      check(BumpLevel.maxOf([null])).isNull;
      check(BumpLevel.maxOf([])).isNull;
    });
  });
}
