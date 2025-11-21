@TestOn('dart-vm')
library;

import 'package:dart_test_tools/src/analyzer_plugin/no_self_package_imports.dart';
import 'package:test/test.dart';

import 'analyzer_plugin_test_helper.dart';

void main() {
  group('no_self_package_imports', () {
    analyzerPluginTest(
      'succeeds by default',
      code: NoSelfPackageImports.code,
      files: const {'test/test.dart': ''},
      expectedOutput: emitsNoIssues(),
    );

    analyzerPluginTest(
      'Accepts files without any imports or exports',
      code: NoSelfPackageImports.code,
      files: const {'test/test.dart': 'const int emptyFile = 1;'},
      expectedOutput: emitsNoIssues(),
    );

    analyzerPluginTest(
      'Rejects src, test and tool files with self library imports',
      onPlatform: const {'windows': Skip('broken for no apparent reason')},
      code: NoSelfPackageImports.code,
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
      expectedOutput: emitsLints(const [
        ('lib/src/src.dart', 1, 1),
        ('lib/src/part.dart', 1, 1),
        ('test/test.dart', 1, 1),
        ('tool/tool.dart', 1, 1),
      ]),
    );

    analyzerPluginTest(
      'Accepts files with ignored self library imports',
      code: NoSelfPackageImports.code,
      files: const {
        'test/test.dart': '''
    // ignore: dart_test_tools/no_self_package_imports
    import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";
    ''',
      },
      expectedOutput: emitsNoIssues(),
    );

    analyzerPluginTest(
      'Accepts files with absolute src imports',
      code: NoSelfPackageImports.code,
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
      expectedOutput: emitsNoIssues(),
    );

    analyzerPluginTest(
      'Accepts files with relative src imports',
      code: NoSelfPackageImports.code,
      files: const {
        'lib/src/src.dart': 'const magicNumber = 42;',
        'lib/lib.dart': 'export "src/src.dart";',
        'bin/bin.dart': 'import "../lib/src/src.dart";',
        'test/test.dart': 'import "../lib/src/src.dart";',
        'tool/tool.dart': 'import "../lib/src/src.dart";',
      },
      expectedOutput: emitsNoIssues(),
    );

    analyzerPluginTest(
      'Accepts files with sdk imports',
      code: NoSelfPackageImports.code,
      files: const {
        'lib/lib.dart': 'import "dart:async";',
        'bin/bin.dart': 'import "dart:async";',
        'test/test.dart': 'import "dart:async";',
        'tool/tool.dart': 'import "dart:async";',
      },
      expectedOutput: emitsNoIssues(),
    );

    analyzerPluginTest(
      'Accepts files with imports of other packages',
      code: NoSelfPackageImports.code,
      files: const {
        'lib/lib.dart': 'import "package:meta/meta.dart";',
        'bin/bin.dart': 'import "package:meta/meta.dart";',
        'test/test.dart': 'import "package:meta/meta.dart";',
        'tool/tool.dart': 'import "package:meta/meta.dart";',
      },
      expectedOutput: emitsNoIssues(),
    );

    analyzerPluginTest(
      'Ignores non dart files',
      code: NoSelfPackageImports.code,
      files: const {
        'test/test.txt':
            'import "package:dart_test_tools_integration_test/dart_test_tools_integration_test.dart";',
      },
      expectedOutput: emitsNoIssues(),
    );
  });
}
