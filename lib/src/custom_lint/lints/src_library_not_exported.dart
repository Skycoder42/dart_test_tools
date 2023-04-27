import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_test_tools/src/lint/common/context_root_extensions.dart';

class SrcLibraryNotExported extends DartLintRule {
  static const _packageExportsKey = 'src_library_not_exported:packageExports';

  static const _code = LintCode(
    name: 'src_library_not_exported',
    problemMessage: 'The library contains public symbols, but '
        'is not exported in any of the package library files.',
    correctionMessage: 'Exports the library from the package or '
        'make all top level elements non-public.',
    errorSeverity: ErrorSeverity.INFO,
  );

  const SrcLibraryNotExported() : super(code: _code);

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    if (!context.sharedState.containsKey(_packageExportsKey)) {
      final resolvedUnitResult = await resolver.getResolvedUnitResult();
      final packageExports =
          await _loadPackageExports(resolvedUnitResult.session.analysisContext)
              .toList();
      context.sharedState[_packageExportsKey] = packageExports;
    }

    return super.startUp(resolver, context);
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final exports =
        context.sharedState[_packageExportsKey] as List<ExportDirective>;

    final exportedElements = <Element>[];
    context.registry
      ..addDeclaration((node) {
        final Iterable<Element?> elements;
        if (node is TopLevelVariableDeclaration) {
          elements = node.variables.variables.map((v) => v.declaredElement);
        } else {
          elements = [node.declaredElement];
        }

        exportedElements.addAll(
          elements
              .whereType<Element>()
              .where((element) => element.isExportable),
        );
      });
    context.addPostRunCallback(() {
      // TODO evaluate result
    });
  }

  Stream<ExportDirective> _loadPackageExports(
    AnalysisContext context,
  ) async* {
    for (final path in context.contextRoot.analyzedFiles()) {
      if (!path.endsWith('.dart')) {
        continue;
      }

      if (context.contextRoot.lib.contains(path) &&
          !context.contextRoot.src.contains(path)) {
        yield* _scanForExports(context, path);
      }
    }
  }

  Stream<ExportDirective> _scanForExports(
    AnalysisContext context,
    String path,
  ) async* {
    final unit = await _loadCompilationUnit(context, path);
    if (unit == null) {
      return;
    }

    yield* Stream.fromIterable(
      unit.directives.whereType<ExportDirective>(),
    );
  }

  Future<CompilationUnit?> _loadCompilationUnit(
    AnalysisContext context,
    String path,
  ) async {
    final session = context.currentSession;
    final compilationUnitAstResult = await session.getResolvedUnit(path);
    if (compilationUnitAstResult is ResolvedUnitResult) {
      if (!compilationUnitAstResult.exists) {
        print('$path was resolved, but does not exist');
        return null;
      }

      if (compilationUnitAstResult.isPart) {
        return null;
      }

      return compilationUnitAstResult.unit;
    } else {
      print(compilationUnitAstResult);
      return null;
    }
  }
}

extension _ElementX on Element {
  bool get isExportable =>
      isPublic &&
      !hasInternal &&
      !hasVisibleForTesting &&
      !hasVisibleForOverriding;
}
