import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_test_tools/src/lint/common/context_root_extensions.dart';
import 'package:synchronized/synchronized.dart';

import 'package:path/path.dart' as path;

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

  static final _sessionLocks = Expando<Lock>();
  static final _sessionExports = Expando<Set<String>>();

  const SrcLibraryNotExported() : super(code: _code);

  @override
  List<String> get filesToAnalyze => [
        'lib/**.dart',
      ];

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    if (!context.sharedState.containsKey(_packageExportsKey)) {
      final resolvedUnitResult = await resolver.getResolvedUnitResult();
      final session = resolvedUnitResult.session;
      final lock = _sessionLocks[session] ??= Lock();
      final packageExports = await lock.synchronized(
        () async => _sessionExports[session] ??=
            await _loadExportedFilesSet(session.analysisContext),
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
    print('------------${resolver.path}');

    final exports = context.sharedState[_packageExportsKey] as Set<String>;

    final exportedElements = <Element>[];
    context
      ..registry.addCompilationUnit((node) {
        final element = node.declaredElement;
        if (element == null) {
          return;
        }

        print(node.declarations);

        // if (element.source != element.librarySource) {
        //   return;
        // }

        final contextRoot = element.session.analysisContext.contextRoot;
        if (contextRoot.src.contains(element.librarySource.fullName)) {
          node.declarations
              .expand(_declaredElements)
              .where((element) => element.isExportable)
              .forEach(exportedElements.add);
        } else if (contextRoot.lib.contains(element.librarySource.fullName)) {
          // TODO ???
        }
      })
      ..addPostRunCallback(() {
        if (exportedElements.isEmpty) {
          return;
        }

        if (exports.contains(resolver.path)) {
          return;
        }

        for (final element in exportedElements) {
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

  Future<Set<String>> _loadExportedFilesSet(AnalysisContext context) async {
    final set = HashSet(equals: path.equals, hashCode: path.hash);
    await _loadPackageExports(context).forEach(set.add);
    return set;
  }

  Stream<String> _loadPackageExports(
    AnalysisContext context,
  ) async* {
    for (final path in context.contextRoot.analyzedFiles()) {
      if (!path.endsWith('.dart')) {
        continue;
      }

      if (!context.contextRoot.lib.contains(path)) {
        continue;
      }

      if (context.contextRoot.src.contains(path)) {
        continue;
      }

      yield* _scanForExports(context, path);
    }
  }

  Stream<String> _scanForExports(
    AnalysisContext context,
    String path,
  ) async* {
    final unit = await _loadCompilationUnit(context, path);
    if (unit == null) {
      return;
    }

    final exportedSources = unit.directives
        .whereType<ExportDirective>()
        .expand(
          (e) => [e.element?.uri].followedBy(
            e.configurations.map((c) => c.resolvedUri),
          ),
        )
        .whereType<DirectiveUriWithSource>()
        .map((u) => u.source.fullName);

    yield* Stream.fromIterable(exportedSources);
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
