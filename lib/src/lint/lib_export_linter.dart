import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' show relative;

import 'common/context_root_extensions.dart';
import 'common/file_result.dart';
import 'common/linter.dart';
import 'common/linter_mixin.dart';

part 'lib_export_linter.freezed.dart';

@freezed
class _ExportPartResult with _$_ExportPartResult {
  const factory _ExportPartResult.path(String path) = _ExportPartPathResult;
  const factory _ExportPartResult.skip(ResultLocation resultLocation) =
      _ExportPartSkipResult;
}

class LibExportLinter with LinterMixin implements Linter {
  @override
  late AnalysisContextCollection contextCollection;

  @override
  @internal
  final Logger logger;

  @override
  String get name => 'lib-export';

  @override
  String get description => 'Checks if all files within the lib/src directy, '
      'that have package visible declarations are exported somwhere '
      'from within the lib folder.';

  LibExportLinter([Logger? logger]) : logger = logger ?? Logger('lib-export');

  @override
  Stream<FileResult> call() async* {
    final sources = <String>{};
    final exports = <String>{};

    for (final context in contextCollection.contexts) {
      try {
        for (final path in context.contextRoot.analyzedFiles()) {
          if (!isDartFile(path)) {
            continue;
          }

          if (context.contextRoot.src.contains(path)) {
            final srcResult = await _scanSrcFile(context, path);
            if (srcResult != null) {
              yield srcResult;
            } else {
              sources.add(path);
            }
          } else if (context.contextRoot.lib.contains(path)) {
            await for (final result in _scanForExports(context, path)) {
              if (result is _ExportPartSkipResult) {
                yield FileResult.skipped(
                  reason: 'Is a part file',
                  resultLocation: result.resultLocation,
                );
              } else if (result is _ExportPartPathResult) {
                exports.add(result.path);
              } else {
                throw StateError('Unexpected _ExportPartResult: $result');
              }
            }
          } else {
            // ignore all files not in the lib directory
          }
        }
      } on AnalysisException catch (e, s) {
        yield e.toFailure(s);
      }
    }

    yield* _evaluteExportResults(sources, exports);
  }

  Future<FileResult?> _scanSrcFile(AnalysisContext context, String path) async {
    try {
      final resultLocation = ResultLocation.fromFile(
        context: context,
        path: path,
      );

      final unit = await loadCompilationUnit(context, path);
      if (unit == null) {
        return FileResult.skipped(
          reason: 'Is a part file',
          resultLocation: resultLocation,
        );
      }

      if (await _hasExportedElements(context, path, unit)) {
        return null;
      } else {
        return FileResult.accepted(resultLocation: resultLocation);
      }
    } on AnalysisException catch (e, s) {
      return e.toFailure(s);
    }
  }

  Future<bool> _hasExportedElements(
    AnalysisContext context,
    String path,
    CompilationUnit unit,
  ) async {
    // check if it exports any other files
    if (unit.directives.whereType<ExportDirective>().isNotEmpty) {
      logDebug(
        ResultLocation.fromFile(context: context, path: path),
        'File has export directives',
      );
      return true;
    }

    // check if any top level declarations are public
    for (final declaration in unit.declarations) {
      final Iterable<Element?> elements;
      if (declaration is TopLevelVariableDeclaration) {
        elements =
            declaration.variables.variables.map((v) => v.declaredElement);
      } else {
        elements = [declaration.declaredElement];
      }

      for (final element in elements) {
        if (element == null) {
          throw AnalysisException(
            ResultLocation.fromFile(
              context: context,
              path: path,
              node: declaration,
              lineInfo: unit.lineInfo,
            ),
            'Unabled to access declaration element for: %{code}',
          );
        }

        if (element.isExportable) {
          logDebug(
            ResultLocation.fromFile(
              context: context,
              path: path,
              lineInfo: unit.lineInfo,
              node: declaration,
            ),
            'File has package-public declaration',
          );
          return true;
        }
      }
    }

    return false;
  }

  Stream<_ExportPartResult> _scanForExports(
    AnalysisContext context,
    String path,
  ) async* {
    final unit = await loadCompilationUnit(context, path);
    if (unit == null) {
      yield _ExportPartResult.skip(
        ResultLocation.fromFile(context: context, path: path),
      );
      return;
    }

    yield* _getExports(context, path, unit);
  }

  Stream<_ExportPartResult> _getExports(
    AnalysisContext context,
    String path,
    CompilationUnit compilationUnit,
  ) async* {
    final exportDirectives =
        compilationUnit.directives.whereType<ExportDirective>();
    for (final exportDirective in exportDirectives) {
      final resultLocation = ResultLocation.fromFile(
        context: context,
        path: path,
        node: exportDirective,
        lineInfo: compilationUnit.lineInfo,
      );

      final allExportSources = [
        exportDirective.uriSource,
        ...exportDirective.configurations.map((c) => c.uriSource),
      ];

      for (final exportSource in allExportSources) {
        // skip invalid sources
        if (exportSource == null) {
          logWarning(
            resultLocation,
            'Unable to resolve source of directive %{code}',
          );
          continue;
        }

        if (!_isSrcExport(
          context: context,
          exportDirective: exportDirective,
          exportSource: exportSource,
          resultLocation: resultLocation,
        )) {
          continue;
        }

        yield _ExportPartResult.path(exportSource.fullName);

        final sourceContext = _findContextWithExcludes(exportSource.fullName);
        if (sourceContext != null) {
          yield* _scanForExports(sourceContext, exportSource.fullName);
        } else {
          logWarning(
            resultLocation,
            'Unabled to scan ${relative(
              exportSource.fullName,
              from: context.contextRoot.root.path,
            )} for further exports, '
            'detected from %{code}',
          );
        }
      }
    }
  }

  bool _isSrcExport({
    required AnalysisContext context,
    required ExportDirective exportDirective,
    required Source exportSource,
    required ResultLocation resultLocation,
  }) {
    // skip non package sources
    final sourceUri = exportSource.uri;
    if (!sourceUri.isScheme('package')) {
      logDebug(
        resultLocation,
        'Export is not a package export',
      );
      return false;
    }

    // skip package exports of different packages
    final exportPackageName = sourceUri.pathSegments.first;
    if (exportPackageName != context.contextRoot.pubspec.name) {
      logDebug(
        resultLocation,
        'Export is from external package',
      );
      return false;
    }

    // skip non src exports
    final sourcePath = exportSource.fullName;
    if (!context.contextRoot.src.contains(sourcePath)) {
      logDebug(
        resultLocation,
        'Export is not a src file',
      );
      return false;
    }

    return true;
  }

  Stream<FileResult> _evaluteExportResults(
    Set<String> sources,
    Set<String> exports,
  ) async* {
    for (final source in sources) {
      final resultLocation = ResultLocation.fromFile(
        context: contextCollection.contextFor(source),
        path: source,
      );
      if (exports.contains(source)) {
        yield FileResult.accepted(resultLocation: resultLocation);
      } else {
        yield FileResult.rejected(
          reason: 'Source file is not exported anywhere',
          resultLocation: resultLocation,
        );
      }
    }

    for (final export in exports.difference(sources)) {
      final context = _findContextWithExcludes(export);
      if (context == null) {
        continue;
      }

      logWarning(
        ResultLocation.fromFile(
          context: context,
          path: export,
        ),
        'Found exported source that is not covered by the analyzer',
      );
    }
  }

  AnalysisContext? _findContextWithExcludes(String path) {
    try {
      return contextCollection.contextFor(path);
      // ignore: avoid_catching_errors
    } on StateError {
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
