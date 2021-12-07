import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

import 'import_analyzer_base.dart';

/// Scans for absolute library imports
///
/// Scans all files within the src directory for package imports of that very
/// same package that are not relative.
class RelativeImportAnalyzer extends ImportAnalyzerBase {
  final String packageRoot;
  final String packageName;

  RelativeImportAnalyzer({
    required this.packageRoot,
    required this.packageName,
    required AnalysisContextCollection contextCollection,
    Logger? parentLogger,
  }) : super(
          contextCollection: contextCollection,
          logger: Logger(
            '${parentLogger != null ? '${parentLogger.fullName}.' : ''}RelativeImportAnalyzer',
          ),
        );

  @override
  String get scannerDescription =>
      'Checking for non relative self imports in lib...';

  @override
  bool shouldAnalyze(String path) {
    // only analyze files that are inside of the "lib" directory
    final libDir = join(packageRoot, 'lib');
    return isWithin(libDir, path);
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

    // reject package imports of same package
    return false;
  }
}
