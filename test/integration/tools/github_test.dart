// ignore: test_library_import
import 'dart:io';

import 'package:dart_test_tools/tools.dart';
import 'package:test/test.dart';

void main() {
  group('$Github', () {
    group('env', () {
      test('runnerTemp returns correct value', () {
        expect(
          Github.env.runnerTemp,
          Platform.environment['RUNNER_TEMP'],
        );
      });

      test('githubWorkspace returns correct value', () {
        expect(
          Github.env.githubWorkspace,
          Platform.environment['GITHUB_WORKSPACE'],
        );
      });
    });
  });
}
