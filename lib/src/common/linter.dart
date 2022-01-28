import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:logging/logging.dart';

import 'file_result.dart';

abstract class Linter {
  Linter._();

  Logger get logger;

  AnalysisContextCollection get contextCollection;
  set contextCollection(AnalysisContextCollection value);

  String get name;

  String get description;

  Stream<FileResult> call();
}
