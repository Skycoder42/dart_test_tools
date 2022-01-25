import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

abstract class AnalyzerBase {
  final AnalysisContextCollection contextCollection;
  final Logger logger;

  const AnalyzerBase({
    required this.contextCollection,
    required this.logger,
  });

  Future<bool> runAnalysis();

  @protected
  Future<CompilationUnit?> analyzeFile(
    AnalysisContext context,
    String path,
  ) async {
    final session = context.currentSession;
    final compilationUnitAstResult = await session.getResolvedUnit(path);
    if (compilationUnitAstResult is ResolvedUnitResult) {
      if (!compilationUnitAstResult.exists) {
        logger.severe('File $path does not exist');
        return null;
      }

      if (compilationUnitAstResult.isPart) {
        logSkipFile(path, 'is a part file');
        return null;
      }

      if (compilationUnitAstResult.errors.isNotEmpty) {
        logger.severe('File $path has analysis errors:');
        compilationUnitAstResult.errors.forEach(logger.severe);
        return null;
      }

      return compilationUnitAstResult.unit;
    } else {
      logger.severe(
        'File $path could not be analyzed, $compilationUnitAstResult',
      );
      return null;
    }
  }

  @protected
  void logSkipFile(String path, String reason) =>
      logger.finest('Skipping $path, $reason');
}

extension ContextRootX on ContextRoot {
  Pubspec get pubspec {
    final pubspecFile = root.getChildAssumingFile('pubspec.yaml');
    assert(pubspecFile.exists);
    final pubspecData = pubspecFile.readAsStringSync();
    return Pubspec.parse(pubspecData);
  }

  Folder get lib => root.getChildAssumingFolder('lib');

  Folder get src => root.getChildAssumingFolder('lib/src');
}
