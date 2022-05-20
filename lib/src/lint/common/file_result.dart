import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' show relative;

part 'file_result.freezed.dart';

@internal
@freezed
class ResultContext with _$ResultContext {
  const ResultContext._();

  @literal
  // ignore: sort_unnamed_constructors_first
  const factory ResultContext({
    required AnalysisContext context,
    required String path,
    required LineInfo? lineInfo,
  }) = _ResultContext;

  ResultLocation createLocation([AstNode? node]) => ResultLocation.fromFile(
        context: context,
        path: path,
        node: node,
        lineInfo: lineInfo,
      );
}

@freezed
class ResultLocation with _$ResultLocation {
  const ResultLocation._();

  @literal
  @internal
  // ignore: sort_unnamed_constructors_first
  const factory ResultLocation({
    required String relPath,
    CharacterLocation? location,
    String? codeSnippit,
  }) = _ResultLocation;

  @internal
  factory ResultLocation.fromFile({
    required AnalysisContext context,
    required String path,
    AstNode? node,
    LineInfo? lineInfo,
  }) =>
      ResultLocation(
        relPath: relative(path, from: context.contextRoot.root.path),
        location: node != null ? lineInfo?.getLocation(node.offset) : null,
        codeSnippit: node?.toSource(),
      );

  String get path => relPath + (location != null ? ':$location' : '');

  String formatMessage(String message) => codeSnippit != null
      ? message.replaceAll('%{code}', codeSnippit!)
      : message;

  String createLogMessage(String message) =>
      '$path - ${formatMessage(message)}';
}

@freezed
class FileResult with _$FileResult {
  @literal
  const factory FileResult.accepted({
    required ResultLocation resultLocation,
  }) = FileResultAccepted;

  @literal
  const factory FileResult.rejected({
    required String reason,
    required ResultLocation resultLocation,
  }) = FileResultRejected;

  @literal
  const factory FileResult.skipped({
    required String reason,
    required ResultLocation resultLocation,
  }) = FileResultSkipped;

  @literal
  const factory FileResult.failure({
    required String error,
    StackTrace? stackTrace,
    required ResultLocation resultLocation,
  }) = FileResultFailure;
}
