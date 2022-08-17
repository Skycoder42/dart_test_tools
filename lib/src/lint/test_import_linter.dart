import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'common/context_root_extensions.dart';
import 'common/file_linter.dart';
import 'common/file_result.dart';
import 'common/linter_mixin.dart';

class TestImportLinter extends FileLinter with LinterMixin {
  @override
  late AnalysisContextCollection contextCollection;

  @override
  @internal
  final Logger logger;

  @override
  String get name => 'test-import';

  @override
  String get description => 'Checks if test files import sources only directly '
      'via src imports instead of global library imports.';

  TestImportLinter([Logger? logger]) : logger = logger ?? Logger('test-import');

  @override
  bool shouldAnalyze(String path) {
    if (!isDartFile(path)) {
      return false;
    }

    final context = contextCollection.contextFor(path);
    return context.contextRoot.test.contains(path);
  }

  @override
  Future<FileResult> analyzeFile(String path) async {
    assert(shouldAnalyze(path));

    final context = contextCollection.contextFor(path);
    try {
      final unit = await loadCompilationUnit(context, path);
      if (unit == null) {
        return FileResult.skipped(
          reason: 'Is a part file',
          resultLocation: ResultLocation.fromFile(context: context, path: path),
        );
      }
      return _analyzeUnit(context, path, unit);
    } on AnalysisException catch (e, s) {
      return e.toFailure(s);
    }
  }

  FileResult _analyzeUnit(
    AnalysisContext context,
    String path,
    CompilationUnit compilationUnit,
  ) {
    final resultContext = ResultContext(
      context: context,
      path: path,
      lineInfo: compilationUnit.lineInfo,
    );

    final directives =
        compilationUnit.directives.whereType<NamespaceDirective>();
    for (final directive in directives) {
      if (!_directiveIsValid(resultContext, directive)) {
        return FileResult.rejected(
          reason: 'Found self import that is not from src: %{code}',
          resultLocation: resultContext.createLocation(directive),
        );
      }
    }

    return FileResult.accepted(
      resultLocation: resultContext.createLocation(),
    );
  }

  bool _directiveIsValid(
    ResultContext resultContext,
    NamespaceDirective directive,
  ) {
    // accept package imports with an exclusion import
    if (hasIgnoreComment(
      directive.firstTokenAfterCommentAndMetadata,
      'test_library_import',
    )) {
      logDebug(
        resultContext.createLocation(directive),
        'Allowing ignored source import',
      );
      return true;
    }

    final DirectiveUri? directiveUri;
    if (directive is ImportDirective) {
      directiveUri = directive.element2?.uri;
    } else if (directive is ExportDirective) {
      directiveUri = directive.element2?.uri;
    } else {
      logWarning(
        resultContext.createLocation(directive),
        'Unsupported directive type: ${directive.runtimeType}',
      );
      return true;
    }

    final directiveSources = [
      directiveUri,
      ...directive.configurations.map((c) => c.resolvedUri),
    ];

    for (final directiveSource in directiveSources) {
      if (!_directiveSourceIsValid(
        resultContext,
        directive,
        directiveSource,
      )) {
        return false;
      }
    }

    return true;
  }

  bool _directiveSourceIsValid(
    ResultContext resultContext,
    NamespaceDirective directive,
    DirectiveUri? directiveUri,
  ) {
    if (directiveUri is! DirectiveUriWithSource) {
      logWarning(
        resultContext.createLocation(directive),
        'Invalid source for directive: %{code}',
      );
      return false;
    }

    final directiveSource = directiveUri.source;
    // Accept imports that are not package imports
    if (!directiveSource.uri.isScheme('package')) {
      logDebug(
        resultContext.createLocation(directive),
        'Accepting non package import',
      );
      return true;
    }

    // accept package imports of different packages
    final sourcePath = directiveSource.fullName;
    final contextRoot = resultContext.context.contextRoot;
    if (!contextRoot.lib.contains(sourcePath)) {
      logDebug(
        resultContext.createLocation(directive),
        'Accepting external package import',
      );
      return true;
    }

    // accept package imports that import from "src"
    if (contextRoot.src.contains(sourcePath)) {
      logDebug(
        resultContext.createLocation(directive),
        'Accepting self src import',
      );
      return true;
    }

    return false;
  }
}
