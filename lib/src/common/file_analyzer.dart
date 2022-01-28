import 'package:analyzer/dart/analysis/analysis_context_collection.dart';

import 'file_result.dart';

abstract class FileAnalyzer {
  FileAnalyzer._();

  AnalysisContextCollection get contextCollection;

  bool shouldAnalyze(String path);

  Future<FileResult> analyzeFile(String path);

  static Iterable<String> collectFilesFor(FileAnalyzer analyzer) =>
      analyzer.contextCollection.contexts
          .expand((context) => context.contextRoot.analyzedFiles())
          .where((path) => analyzer.shouldAnalyze(path));
}
