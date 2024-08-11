@TestOn('dart-vm')
library src_library_not_exported_test;

import 'package:test/test.dart';

import 'custom_lint_test_helper.dart';

void main() {
  group('src_library_not_exported',
      skip:
          'Disabled until https://github.com/invertase/dart_custom_lint/issues/261 is fixed',
      () {
    customLintTest(
      'succeeds by default',
      files: const {
        'lib/src/src.dart': '',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'reports unexported files in src',
      files: const {
        'lib/lib.dart': 'const int meaningOfLife = 42;',
        'lib/other/other.dart': 'const int meaningOfLife = 42;',
        'lib/src/src.dart': 'const int meaningOfLife = 42;',
        'lib/src/part.dart': 'part "part.g.dart";',
        'lib/src/part.g.dart': '''
part of "part.dart";
const int meaningOfLife = 42;
''',
        'lib/src/sub/sub.dart': 'const int meaningOfLife = 42;',
        'bin/bin.dart': 'const int meaningOfLife = 42;',
        'tool/tool.dart': 'const int meaningOfLife = 42;',
        'test/test.dart': 'const int meaningOfLife = 42;',
        'example/example.dart': 'const int meaningOfLife = 42;',
      },
      expectedExitCode: 1,
      expectedOutput: emitsCustomLint(
        'src_library_not_exported',
        const [
          'lib/src/src.dart:1:11',
          'lib/src/part.g.dart:2:11',
          'lib/src/sub/sub.dart:1:11',
        ],
      ),
    );

    customLintTest(
      'accepts exported sources',
      files: const {
        'lib/lib.dart': '''
export "src/src.dart";
export "src/part.dart";
''',
        'lib/src/src.dart': 'const int meaningOfLife = 42;',
        'lib/src/part.dart': 'part "part.g.dart";',
        'lib/src/part.g.dart': '''
part of "part.dart";
const int partOfLife = 24;
''',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Accepts files non public declarations',
      files: const {
        'lib/src/private.dart': 'const int _meaningOfLife = 42;',
        'lib/src/internal.dart': '''
import 'package:meta/meta.dart';
@internal
const int meaningOfLife = 42;
''',
        'lib/src/visibleForTesting.dart': '''
import 'package:meta/meta.dart';
@visibleForTesting
const int meaningOfLife = 42;
''',
        'lib/src/visibleForOverriding.dart': '''
import 'package:meta/meta.dart';
@visibleForOverriding
const int meaningOfLife = 42;
''',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'reports all public symbols in file',
      files: const {
        'lib/src/src.dart': '''
const int meaningOfLife = 42;

const int _partOfLife = 24;

class MyClass {}
''',
      },
      expectedExitCode: 1,
      expectedOutput: emitsCustomLint(
        'src_library_not_exported',
        const [
          'lib/src/src.dart:1:11',
          'lib/src/src.dart:5:7',
        ],
      ),
    );

    customLintTest(
      'does not report ignored entries',
      files: const {
        'lib/src/src.dart': '''
// ignore: src_library_not_exported
const int meaningOfLife = 42;

const int _partOfLife = 24;

class MyClass {}
''',
      },
      expectedExitCode: 1,
      expectedOutput: emitsCustomLint(
        'src_library_not_exported',
        const [
          'lib/src/src.dart:6:7',
        ],
      ),
    );

    customLintTest(
      'only cares for exports, not imports',
      files: const {
        'lib/lib.dart': 'import "src/src.dart";',
        'lib/src/src.dart': 'const int meaningOfLife = 42;',
      },
      expectedExitCode: 1,
      expectedOutput: emitsCustomLint(
        'src_library_not_exported',
        const [
          'lib/src/src.dart:1:11',
        ],
      ),
    );

    customLintTest(
      'can detect deeply nested exports and handles loops correctly',
      files: const {
        'lib/lib.dart': 'export "other/other.dart";',
        'lib/other/other.dart': 'export "../src/top.dart";',
        'lib/src/top.dart': 'export "sub/master.dart";',
        'lib/src/sub/master.dart': '''
export "impl.dart";
export "loop/loop1.dart";
''',
        'lib/src/sub/impl.dart': 'const int meaningOfLife = 42;',
        'lib/src/sub/loop/loop1.dart': '''
export "loop2.dart"
const int loop1 = 2;
''',
        'lib/src/sub/loop/loop2.dart': '''
export "loop1.dart"
const int loop2 = 1;
''',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'can detect partial exports',
      files: const {
        'lib/lib.dart': 'export "src/src.dart" show symbol1;',
        'lib/src/src.dart': '''
const int symbol1 = 1;
const int symbol2 = 2;
''',
      },
      expectedExitCode: 1,
      expectedOutput: emitsCustomLint(
        'src_library_not_exported',
        const [
          'lib/src/src.dart:2:11',
        ],
      ),
      skip: 'Not implemented yet',
    );

    customLintTest(
      'does not run rule if not published',
      files: const {
        'pubspec.yaml': 'publish_to: none',
        'lib/src/src.dart': 'const int meaningOfLife = 42;',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );

    customLintTest(
      'Ignores non dart files',
      files: const {
        'lib/src/src.txt': 'const int meaningOfLife = 42;',
      },
      expectedExitCode: 0,
      expectedOutput: emitsNoIssues(),
    );
  });
}
