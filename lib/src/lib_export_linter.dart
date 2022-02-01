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
      'from within the lib folder';

  LibExportLinter([Logger? logger]) : logger = logger ?? Logger('lib-export');

  @override
  Stream<FileResult> call() async* {
    for (final context in contextCollection.contexts) {
      try {
        final sources = <String>{};
        final exports = <String>{};

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

        yield* _evaluteExportResults(context, sources, exports);
      } on AnalysisException catch (e, s) {
        yield e.toFailure(s);
      }
    }
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
      final allExportSources = [
        exportDirective.uriSource,
        ...exportDirective.configurations.map((c) => c.uriSource),
      ];

      for (final exportSource in allExportSources) {
        // skip invalid sources
        if (exportSource == null) {
          logWarning(
            ResultLocation.fromFile(
              context: context,
              path: path,
              node: exportDirective,
              lineInfo: compilationUnit.lineInfo,
            ),
            'Unable to resolve source of directive %{code}',
          );
          continue;
        }

        if (!_isSrcExport(
          context: context,
          exportDirective: exportDirective,
          exportSource: exportSource,
        )) {
          continue;
        }

        yield _ExportPartResult.path(exportSource.fullName);

        try {
          yield* _scanForExports(
            contextCollection.contextFor(exportSource.fullName),
            exportSource.fullName,
          );
          // ignore: avoid_catching_errors
        } on StateError catch (error, stackTrace) {
          logWarning(
            ResultLocation.fromFile(
              context: context,
              path: path,
              node: exportDirective,
              lineInfo: compilationUnit.lineInfo,
            ),
            'Unabled to scan ${relative(
              exportSource.fullName,
              from: context.contextRoot.root.path,
            )} for further exports, '
            'detected from %{code}',
            error,
            stackTrace,
          );
        }
      }
    }
  }

  bool _isSrcExport({
    required AnalysisContext context,
    required ExportDirective exportDirective,
    required Source exportSource,
  }) {
    // skip non package sources
    final sourceUri = exportSource.uri;
    if (!sourceUri.isScheme('package')) {
      return false;
    }

    // skip package exports of different packages
    final exportPackageName = sourceUri.pathSegments.first;
    if (exportPackageName != context.contextRoot.pubspec.name) {
      return false;
    }

    // skip non src exports
    final sourcePath = exportSource.fullName;
    if (!context.contextRoot.src.contains(sourcePath)) {
      return false;
    }

    return true;
  }

  Stream<FileResult> _evaluteExportResults(
    AnalysisContext context,
    Set<String> sources,
    Set<String> exports,
  ) async* {
    for (final source in sources) {
      final resultLocation = ResultLocation.fromFile(
        context: context,
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
      logWarning(
        ResultLocation.fromFile(
          context: context,
          path: export,
        ),
        'Found exported source that is not covered by the analyzer',
      );
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
