import 'package:analyzer/dart/analysis/analysis_context_collection.dart';

import 'file_result.dart';

abstract class PackageAnalyzer {
  PackageAnalyzer._();

  AnalysisContextCollection get contextCollection;

  Stream<FileResult> analyzePackage();
}
