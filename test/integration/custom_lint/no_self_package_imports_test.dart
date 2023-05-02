import 'package:test/test.dart';

import 'custom_lint_test_helper.dart';

void main() {
  group('no_self_package_imports', () {
    customLintTest(
      'succeeds by default',
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Accepts files without any imports or exports',
      files: const {
        'test/test.dart': 'const int emptyFile = 1;',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Rejects files with self library imports',
      files: const {
        'test/test.dart':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
      },
      expectedExitCode: 1,
      expectedOutput: emitsCustomLint(
        'no_self_package_imports',
        const ['test/test.dart:1:8'],
      ),
    );
  });
}
