import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart' hide FileResult;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'file_result.dart';

class AnalysisException implements Exception {
  final String message;
  final ResultLocation resultLocation;

  AnalysisException(this.resultLocation, this.message);

  @override
  String toString() => message;

  FileResult toFailure([StackTrace? stackTrace]) => FileResult.failure(
        error: message,
        resultLocation: resultLocation,
        stackTrace: stackTrace,
      );
}

mixin AnalyzerMixin {
  @visibleForOverriding
  Logger? get logger;

  @protected
  bool isDartFile(String path) => path.endsWith('.dart');

  @protected
  Future<CompilationUnit?> loadCompilationUnit(
    AnalysisContext context,
    String path,
  ) async {
    final session = context.currentSession;
    final compilationUnitAstResult = await session.getResolvedUnit(path);
    if (compilationUnitAstResult is ResolvedUnitResult) {
      if (!compilationUnitAstResult.exists) {
        throw AnalysisException(
          ResultLocation.fromFile(context: context, path: path),
          'File does not exist',
        );
      }

      if (compilationUnitAstResult.isPart) {
        return null;
      }

      if (compilationUnitAstResult.errors.isNotEmpty) {
        for (final error in compilationUnitAstResult.errors) {
          logWarning(
            ResultLocation.fromFile(
              context: context,
              path: path,
            ),
            error.message,
          );
        }
      }

      return compilationUnitAstResult.unit;
    } else {
      throw AnalysisException(
        ResultLocation.fromFile(context: context, path: path),
        compilationUnitAstResult.toString(),
      );
    }
  }

  @protected
  bool hasIgnoreComment(Token token, String comment) {
    var commentToken = token.precedingComments;
    final cast = _TokenCastHelper(commentToken);
    while (commentToken != null) {
      if (commentToken.value() == '// ignore: $comment') {
        return true;
      }
      commentToken = cast(commentToken.next);
    }

    return false;
  }

  @protected
  void logWarning(
    ResultLocation location,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      logger?.warning(
        location.createLogMessage(message),
        error,
        stackTrace,
      );
}

class _TokenCastHelper<TToken extends Token> {
  // ignore: avoid_unused_constructor_parameters
  _TokenCastHelper(TToken? token);

  TToken? call(Token? token) => token is TToken ? token : null;
}
