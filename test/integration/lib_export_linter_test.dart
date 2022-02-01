import 'package:dart_test_tools/src/lib_export_linter.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'integration_test_helper.dart';

void main() {
  setUpAll(() {
    // ignore: avoid_print
    Logger.root.onRecord.listen(print);
    Logger.root.level = Level.ALL;
  });

  group('LibExportLinter', () {
    analysisTest(
      'Succeeds by default',
      createLinter: LibExportLinter.new,
      expectResults: emitsDone,
    );

    analysisTest(
      'ignores non-dart files',
      createLinter: LibExportLinter.new,
      files: const {
        'lib/help.txt': '',
        'lib/src/help.dart.txt': '',
      },
      expectResults: emitsDone,
    );

    analysisTest(
      'ignores non-lib files',
      createLinter: LibExportLinter.new,
      files: const {
        'bin/file.dart': 'const int meaningOfLife = 42;',
        'tool/file.dart': 'const int meaningOfLife = 42;',
        'test/file.dart': 'const int meaningOfLife = 42;',
      },
      expectResults: emitsDone,
    );

    analysisTest(
      'Accepts exported sources',
      createLinter: LibExportLinter.new,
      files: const {
        'lib/file.dart': 'export "src/impl.dart";',
        'lib/src/impl.dart': 'const int meaningOfLife = 42;',
      },
      expectResults: emitsInAnyOrder(<dynamic>[
        isAccepted(
          resultLocation: (l) => l.havingRelPath('lib/src/impl.dart'),
        ),
        emitsDone,
      ]),
    );

    analysisTest(
      'Rejects unexported sources',
      createLinter: LibExportLinter.new,
      files: const {
        'lib/file.dart': '',
        'lib/src/impl.dart': 'const int meaningOfLife = 42;',
      },
      expectResults: emitsInAnyOrder(<dynamic>[
        isRejected(
          resultLocation: (l) => l.havingRelPath('lib/src/impl.dart'),
          reason: 'Source file is not exported anywhere',
        ),
        emitsDone,
      ]),
    );

    group('src-files', () {
      analysisTest(
        'Skips part files',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/src/file.dart': 'part of "../library.dart"',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          isSkipped(
            resultLocation: (l) => l.havingRelPath('lib/src/file.dart'),
            reason: 'Is a part file',
          ),
          emitsDone,
        ]),
      );

      analysisTest(
        'Accepts files without public exports',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/src/file.dart': '',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          isAccepted(
            resultLocation: (l) => l.havingRelPath('lib/src/file.dart'),
          ),
          emitsDone,
        ]),
      );

      analysisTest(
        'Accepts files non public declarations',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/src/private.dart': 'const int _meaningOfLife = 42;',
          'lib/src/internal.dart':
              '''
import 'package:meta/meta.dart';
@internal
const int meaningOfLife = 42;
''',
          'lib/src/visibleForTesting.dart':
              '''
import 'package:meta/meta.dart';
@visibleForTesting
const int meaningOfLife = 42;
''',
          'lib/src/visibleForOverriding.dart':
              '''
import 'package:meta/meta.dart';
@visibleForOverriding
const int meaningOfLife = 42;
''',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          isAccepted(
            resultLocation: (l) => l.havingRelPath('lib/src/private.dart'),
          ),
          isAccepted(
            resultLocation: (l) => l.havingRelPath('lib/src/internal.dart'),
          ),
          isAccepted(
            resultLocation: (l) =>
                l.havingRelPath('lib/src/visibleForTesting.dart'),
          ),
          isAccepted(
            resultLocation: (l) =>
                l.havingRelPath('lib/src/visibleForOverriding.dart'),
          ),
          emitsDone,
        ]),
      );

      analysisTest(
        'Accepts files with multiple non public exports',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/src/file.dart':
              '''
import 'package:meta/meta.dart';

const int _meaningOfLife = 42;

@internal
class Test {
  int call() => _meaningOfLife;
}

@visibleForTesting
extension X on Test {
  int run() => call();
}
''',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          isAccepted(
            resultLocation: (l) => l.havingRelPath('lib/src/file.dart'),
          ),
          emitsDone,
        ]),
      );

      analysisTest(
        'Rejects files with public exports',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/src/export.dart': 'export "public.dart";',
          'lib/src/public.dart': 'const int meaningOfLife = 42;',
          'lib/src/mixed.dart':
              '''
const int _left = 0;
const int meaningOfLife = 42;
const int _right = 1;
''',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          isRejected(
            resultLocation: (l) => l.havingRelPath('lib/src/export.dart'),
            reason: 'Source file is not exported anywhere',
          ),
          isRejected(
            resultLocation: (l) => l.havingRelPath('lib/src/public.dart'),
            reason: 'Source file is not exported anywhere',
          ),
          isRejected(
            resultLocation: (l) => l.havingRelPath('lib/src/mixed.dart'),
            reason: 'Source file is not exported anywhere',
          ),
          emitsDone,
        ]),
      );
    });

    group('lib-files', () {
      analysisTest(
        'Skips part files',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/file.dart': 'part of "library.dart"',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          isSkipped(
            resultLocation: (l) => l.havingRelPath('lib/file.dart'),
            reason: 'Is a part file',
          ),
          emitsDone,
        ]),
      );

      analysisTest(
        'Ignores non source exports',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/sdk.dart': 'export "dart:async";',
          'lib/package.dart': 'export "package:meta/meta.dart";',
          'lib/lib.dart': 'export "other.dart";',
        },
        expectResults: emitsDone,
      );

      analysisTest(
        'Fails for non existing referenced exports',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/file.dart': 'export "src/impl.dart";',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          isFailure(
            resultLocation: (l) => l.havingRelPath('lib/src/impl.dart'),
            error: 'File does not exist',
            stackTrace: isNot(StackTrace.empty),
          ),
          emitsDone,
        ]),
      );

      analysisTest(
        'Ignores analysis excluded src files',
        createLinter: LibExportLinter.new,
        files: const {
          'analysis_options.yaml':
              '''
analyzer:
  exclude:
    - lib/src/impl.dart
''',
          'lib/file.dart': 'export "src/impl.dart";',
          'lib/src/impl.dart': 'export "another.dart";',
        },
        expectResults: emitsDone,
      );

      analysisTest(
        'Recursively collects exported files',
        createLinter: LibExportLinter.new,
        files: const {
          'lib/exp1.dart':
              '''
export "src/exp3.dart";
export "src/file1.dart";
export "src/file2.dart";
''',
          'lib/exp2.dart': 'export "src/file3.dart";',
          'lib/src/exp3.dart': '''
export "exp4.dart";
export "exp5.dart";
''',
          'lib/src/exp4.dart': 'export "file4.dart";',
          'lib/src/exp5.dart': 'export "file5.dart";',
          'lib/src/file1.dart': '',
          'lib/src/file2.dart': '',
          'lib/src/file3.dart': '',
          'lib/src/file4.dart': '',
          'lib/src/file5.dart': '',
        },
        expectResults: emitsInAnyOrder(<dynamic>[
          for (var i = 1; i <= 5; ++i)
            isAccepted(
              resultLocation: (l) => l.havingRelPath('lib/src/file$i.dart'),
            ),
          for (var i = 3; i <= 5; ++i)
            isAccepted(
              resultLocation: (l) => l.havingRelPath('lib/src/exp$i.dart'),
            ),
          emitsDone,
        ]),
        expectLog: emitsInAnyOrder(<dynamic>[
          for (var i = 1; i <= 5; ++i)
            isA<LogRecord>()
                .having((r) => r.level, 'level', Level.WARNING)
                .having(
                  (r) => r.message,
                  'message',
                  allOf(
                    contains('file$i.dart'),
                    contains(
                      'Found exported source that '
                      'is not covered by the analyzer',
                    ),
                  ),
                ),
        ]),
      );
    });
  });
}
