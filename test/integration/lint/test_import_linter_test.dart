import 'package:dart_test_tools/src/lint/test_import_linter.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'integration_test_helper.dart';

void main() {
  setUpAll(() {
    // ignore: avoid_print
    Logger.root.onRecord.listen(print);
    Logger.root.level = Level.ALL;
  });

  group('TestImportLinter', () {
    analysisTest(
      'Succeeds by default',
      createLinter: TestImportLinter.new,
      expectResults: emitsDone,
    );

    analysisTest(
      'ignores non-dart files',
      createLinter: TestImportLinter.new,
      files: const {
        'test/help.txt': '',
        'test/unit/help.dart.txt': '',
      },
      expectResults: emitsDone,
    );

    analysisTest(
      'Only scans test files',
      createLinter: TestImportLinter.new,
      files: const {
        'bin/bin.dart': '',
        'lib/lib.dart': '',
        'lib/src/src.dart': '',
        'test/test.dart': '',
      },
      expectResults: emitsInAnyOrder(<dynamic>[
        isAccepted(
          resultLocation: (l) => l.havingRelPath('test/test.dart'),
        ),
        emitsDone,
      ]),
    );

    fileAnalysisTest(
      'Skips part files',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent: 'part of "test_all.dart"',
      expectResult: isSkipped(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
        reason: 'Is a part file',
      ),
    );

    fileAnalysisTest(
      'Accepts files without any imports or exports',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent: 'const int emptyFile = 1;',
      expectResult: isAccepted(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
      ),
    );

    fileAnalysisTest(
      'Rejects files with self libary imports',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent:
          'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
      expectResult: isRejected(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
        reason: 'Found self import that is not from src: %{code}',
      ),
    );

    fileAnalysisTest(
      'Accepts files with ignores self libary imports',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent: '''
// ignore: test_library_import
import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";
''',
      expectResult: isAccepted(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
      ),
    );

    fileAnalysisTest(
      'Accepts files with sdk imports',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent: 'import "dart:async";',
      expectResult: isAccepted(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
      ),
    );

    fileAnalysisTest(
      'Accepts files with relative imports',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent: 'import "../info.dart";',
      expectResult: isAccepted(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
      ),
    );

    fileAnalysisTest(
      'Accepts files with imports of other packages',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent: 'import "package:meta/meta.dart";',
      expectResult: isAccepted(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
      ),
    );

    fileAnalysisTest(
      'Accepts files with imports of src libraries',
      createLinter: TestImportLinter.new,
      fileName: 'test/test.dart',
      fileContent:
          'import "package:dart_test_tools_integration_test/src/src.dart";',
      expectResult: isAccepted(
        resultLocation: (l) => l.havingRelPath('test/test.dart'),
      ),
    );
  });
}
