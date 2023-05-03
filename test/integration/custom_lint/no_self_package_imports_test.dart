@TestOn('dart-vm')
library no_self_package_imports_test;

import 'package:test/test.dart';

import 'custom_lint_test_helper.dart';

void main() {
  group('no_self_package_imports', () {
    customLintTest(
      'succeeds by default',
      files: const {
        'test/test.dart': '',
      },
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
      'Rejects src, test and tool files with self library imports',
      files: const {
        'lib/src/src.dart':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
        'lib/src/part.dart': '''
import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";
part "part.g.dart";
''',
        'lib/src/part.g.dart': 'part of "part.dart";',
        'lib/lib.dart':
            'export "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
        'bin/bin.dart':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
        'test/test.dart':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
        'tool/tool.dart':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
        'example/example.dart':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
      },
      expectedExitCode: 1,
      expectedOutput: emitsCustomLint(
        'no_self_package_imports',
        const [
          'lib/src/src.dart:1:8',
          'lib/src/part.dart:1:8',
          'test/test.dart:1:8',
          'tool/tool.dart:1:8',
        ],
      ),
    );

    customLintTest(
      'Accepts files with ignored self library imports',
      files: const {
        'test/test.dart': '''
// ignore: no_self_package_imports
import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";
''',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Accepts files with absolute src imports',
      files: const {
        'lib/src/src.dart': 'const magicNumber = 42;',
        'lib/lib.dart':
            'export "package:dart_test_tools_integration_test/src/src.dart";',
        'bin/bin.dart':
            'import "package:dart_test_tools_integration_test//src/src.dart";',
        'test/test.dart':
            'import "package:dart_test_tools_integration_test//src/src.dart";',
        'tool/tool.dart':
            'import "package:dart_test_tools_integration_test//src/src.dart";',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Accepts files with relative src imports',
      files: const {
        'lib/src/src.dart': 'const magicNumber = 42;',
        'lib/lib.dart': 'export "src/src.dart";',
        'bin/bin.dart': 'import "../lib/src/src.dart";',
        'test/test.dart': 'import "../lib/src/src.dart";',
        'tool/tool.dart': 'import "../lib/src/src.dart";',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Accepts files with sdk imports',
      files: const {
        'lib/lib.dart': 'import "dart:async";',
        'bin/bin.dart': 'import "dart:async";',
        'test/test.dart': 'import "dart:async";',
        'tool/tool.dart': 'import "dart:async";',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Accepts files with imports of other packages',
      files: const {
        'lib/lib.dart': 'import "package:meta/meta.dart";',
        'bin/bin.dart': 'import "package:meta/meta.dart";',
        'test/test.dart': 'import "package:meta/meta.dart";',
        'tool/tool.dart': 'import "package:meta/meta.dart";',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Ignores non dart files',
      files: const {
        'test/test.txt':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );
  });
}
