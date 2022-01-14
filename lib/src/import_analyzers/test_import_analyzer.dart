import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

import 'import_analyzer_base.dart';

class TestImportAnalyzer extends ImportAnalyzerBase {
  final String packageRoot;
  final String packageName;

  TestImportAnalyzer({
    required this.packageRoot,
    required this.packageName,
    required AnalysisContextCollection contextCollection,
  }) : super(
          contextCollection: contextCollection,
          logger: Logger('test-import-analyzer'),
        );

  @override
  // TODO: implement scannerDescription
  String get scannerDescription =>
      'Checking for library imports in test files...';

  @override
  bool shouldAnalyze(String path) {
    // only analyze files that are inside of the "test" directory
    final testDir = join(packageRoot, 'test');
    return isWithin(testDir, path);
  }

  @override
  bool analyzeDirective(String path, NamespaceDirective directive) {
    assert(shouldAnalyze(path));

    // Accept imports that are not package imports
    final directiveUri = getDirectiveUri(directive);
    if (directiveUri.scheme != 'package') {
      return true;
    }

    // accept package imports of different packages
    final importPackageName = directiveUri.pathSegments.first;
    if (importPackageName != packageName) {
      return true;
    }

    // accept package imports that import from "src"
    final expectedPath = join(importPackageName, 'src');
    if (isWithin(expectedPath, directiveUri.path)) {
      return true;
    }

    // accept package imports with an exclusion import
    final hasImportComment = directive
            .firstTokenAfterCommentAndMetadata.precedingComments
            ?.value()
            .contains('dart_test_tools:ignore-library-import') ??
        false;
    if (hasImportComment) {
      return true;
    }

    // reject library imports of this package
    return false;
  }
}
