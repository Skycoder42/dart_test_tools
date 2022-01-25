import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'import_result.dart';

class _TokenCastHelper<TToken extends Token> {
  // ignore: avoid_unused_constructor_parameters
  _TokenCastHelper(TToken? token);

  TToken? call(Token? token) => token is TToken ? token : null;
}

abstract class ImportAnalyzerBase {
  final AnalysisContextCollection contextCollection;
  final Logger logger;

  ImportAnalyzerBase({
    required this.contextCollection,
    required this.logger,
  });

  Iterable<String> collectTargetFiles() => contextCollection.contexts
      .expand((context) => context.contextRoot.analyzedFiles())
      .where((path) => path.endsWith('.dart'))
      .where(shouldAnalyze);

  Future<bool> runAnalysis([Iterable<String>? filesToAnalyze]) async {
    logger.info(scannerDescription);
    var failed = false;
    final files = filesToAnalyze ?? collectTargetFiles();
    for (final file in files) {
      final result = await _analyzeFile(file);
      result.log(logger);
      failed = failed || result.isFailure;
    }
    return !failed;
  }

  @protected
  String get scannerDescription;

  @protected
  bool shouldAnalyze(String path);

  @protected
  bool analyzeDirective(String path, NamespaceDirective directive);

  @protected
  Uri getDirectiveUri(NamespaceDirective directive) {
    final uriString = directive.uri.stringValue;
    if (uriString == null) {
      throw Exception('Directive is not a valid URI');
    }
    return Uri.parse(uriString);
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

  Future<ImportResult> _analyzeFile(String path) async {
    final context = contextCollection.contextFor(path);
    final session = context.currentSession;
    final compilationUnitAstResult = await session.getResolvedUnit(path);
    if (compilationUnitAstResult is ResolvedUnitResult) {
      if (!compilationUnitAstResult.exists) {
        return ImportResult.failed(
          path: path,
          error: 'File $path does not exist',
          stackTrace: StackTrace.current,
        );
      }

      if (compilationUnitAstResult.isPart) {
        return ImportResult.skipped(
          path: path,
          reason: 'The file is a part-file',
        );
      }

      if (compilationUnitAstResult.errors.isNotEmpty) {
        return ImportResult.skipped(
          path: path,
          reason:
              'The Analyzer detected ${compilationUnitAstResult.errors.length} '
              'problems in the file',
        );
      }

      return _analyzeCompilationUnit(path, compilationUnitAstResult.unit);
    } else {
      return ImportResult.failed(
        path: path,
        error: compilationUnitAstResult,
        stackTrace: StackTrace.current,
      );
    }
  }

  ImportResult _analyzeCompilationUnit(
    String path,
    CompilationUnit compilationUnit,
  ) {
    final lineInfo = compilationUnit.lineInfo;
    if (lineInfo == null) {
      return ImportResult.failed(
        path: path,
        error: 'Failed get line information',
        stackTrace: StackTrace.current,
      );
    }

    final directiveErrors = _analyzeDirectives(
      path,
      lineInfo,
      compilationUnit.directives.whereType<NamespaceDirective>(),
    );

    if (directiveErrors.isEmpty) {
      return ImportResult.accepted(path);
    } else {
      return ImportResult.rejected(
        path: path,
        errors: directiveErrors,
      );
    }
  }

  List<DirectiveError> _analyzeDirectives(
    String path,
    LineInfo lineInfo,
    Iterable<NamespaceDirective> directives,
  ) {
    final errors = <DirectiveError>[];
    for (final directive in directives) {
      if (!analyzeDirective(path, directive)) {
        errors.add(
          DirectiveError(
            directive: directive.toString(),
            line: lineInfo.getLocation(directive.offset).lineNumber,
          ),
        );
      }
    }
    return errors;
  }
}
