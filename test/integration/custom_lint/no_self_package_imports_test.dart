import 'package:test/test.dart';

import 'custom_lint_test_helper.dart';

void main() {
  group('no_self_package_imports', () {
    customLintTest(
      'succeeds by default',
      expectedExitCode: 0,
      expectedOutput: emitsInOrder(<dynamic>[
        'No issues found!',
        emitsDone,
      ]),
    );
  });
}
