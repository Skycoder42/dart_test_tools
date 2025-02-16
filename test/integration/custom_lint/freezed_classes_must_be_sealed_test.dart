@TestOn('dart-vm')
library;

import 'package:test/test.dart';

import 'custom_lint_test_helper.dart';

void main() {
  group(
    'freezed_classes_must_be_sealed',
    skip:
        'Disabled until https://github.com/invertase/dart_custom_lint/issues/261 is fixed',
    () {
      customLintTest(
        'succeeds by default',
        files: const {'test/test.dart': ''},
        expectedExitCode: 0,
        expectedOutput: emitsNoIssues(),
      );

      customLintTest(
        'succeeds for sealed freezed classes',
        files: const {
          'test/test.dart': r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'test.freezed.dart';

@freezed
sealed class Test with _$Test {
  const factory Test() = _Test;
}
''',
        },
        expectedExitCode: 0,
        expectedOutput: emitsNoIssues(),
      );

      customLintTest(
        'fails for freezed classes without the sealed keyword',
        files: const {
          'test/test.dart': r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'test.freezed.dart';

@freezed
class Test with _$Test {
  const factory Test() = _Test;
}
''',
        },
        expectedExitCode: 1,
        expectedOutput: emitsCustomLint(
          'freezed_classes_must_be_sealed',
          const ['test/test.dart:6:1'],
        ),
      );

      customLintTest(
        'Ignores non dart files',
        files: const {
          'test/test.txt': r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'test.freezed.dart';

@freezed
class Test with _$Test {
  const factory Test() = _Test;
}
''',
        },
        expectedExitCode: 0,
        expectedOutput: emitsNoIssues(),
      );
    },
  );
}
