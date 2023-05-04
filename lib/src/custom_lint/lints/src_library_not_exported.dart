import 'dart:collection';

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_test_tools/src/custom_lint/lints/context_root_extensions.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/extension.dart';

import 'package:path/path.dart' as path;

@internal
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

  static final _sessionExports = Expando<Set<String>>();

  const SrcLibraryNotExported() : super(code: _code);

  @override
  List<String> get filesToAnalyze => [
        'lib/src/**.dart',
      ];

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    if (!context.sharedState.containsKey(_packageExportsKey)) {
      final resolvedUnitResult = await resolver.getResolvedUnitResult();
      final session = resolvedUnitResult.session;
      final packageExports = await session.synchronized(
        () async =>
            _sessionExports[session] ??= await _loadPackageExports(session),
      );
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
    final exportedLibraries =
        context.sharedState[_packageExportsKey] as Set<String>;

    context.registry.addCompilationUnit((node) {
      final element = node.declaredElement;
      if (element == null) {
        return;
      }

      final exportableElements = node.declarations
          .expand(_declaredElements)
          .where((e) => e.isExportable)
          .toList();

      if (exportableElements.isEmpty) {
        return;
      }

      final libraryPath = element.librarySource.fullName;
      if (exportedLibraries.contains(libraryPath)) {
        return;
      }

      for (final element in exportableElements) {
        reporter.reportErrorForElement(_code, element);
      }
    });
  }

  Iterable<Element> _declaredElements(CompilationUnitMember declaration) {
    final Iterable<Element?> elements;
    if (declaration is TopLevelVariableDeclaration) {
      elements = declaration.variables.variables.map((v) => v.declaredElement);
    } else {
      elements = [declaration.declaredElement];
    }

    return elements.whereType<Element>();
  }

  Future<Set<String>> _loadPackageExports(
    AnalysisSession session,
  ) async {
    final exportSet = HashSet(equals: path.equals, hashCode: path.hash);
    final contextRoot = session.analysisContext.contextRoot;

    await Future.wait([
      for (final path in contextRoot.analyzedFiles())
        if (_isPackageLibrary(contextRoot, path))
          _scanForExports(session, contextRoot, exportSet, path),
    ]);

    return exportSet;
  }

  bool _isPackageLibrary(ContextRoot contextRoot, String path) {
    if (!path.endsWith('.dart')) {
      return false;
    }

    if (!contextRoot.lib.contains(path)) {
      return false;
    }

    if (contextRoot.src.contains(path)) {
      return false;
    }

    return true;
  }

  Future<void> _scanForExports(
    AnalysisSession session,
    ContextRoot contextRoot,
    Set<String> exportSet,
    String path,
  ) async {
    final unit = await _loadCompilationUnit(session, path);
    if (unit == null) {
      return;
    }

    final exportedSources = unit.directives
        .whereType<ExportDirective>()
        .expand((e) sync* {
          yield e.element?.uri;
          yield* e.configurations.map((c) => c.resolvedUri);
        })
        .whereType<DirectiveUriWithSource>()
        .map((u) => u.source.fullName)
        .where(contextRoot.src.contains);

    await Future.wait([
      for (final source in exportedSources)
        if (exportSet.add(source))
          _scanForExports(session, contextRoot, exportSet, source)
    ]);
  }

  Future<CompilationUnit?> _loadCompilationUnit(
    AnalysisSession session,
    String path,
  ) async {
    final compilationUnitAstResult = await session.getResolvedUnit(path);
    if (compilationUnitAstResult is ResolvedUnitResult) {
      if (!compilationUnitAstResult.exists) {
        print('WARNING: $path was resolved, but does not exist');
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
