@internal
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:glob/list_local_fs.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'auto_export_config.dart';
import 'unresolved_export.dart';
import 'yaml_serializable.dart';

class ExportResolver {
  Stream<SingleExportDefinition> resolveExports(
    Directory relativeTo,
    Iterable<ExportDefinition> exports,
  ) async* {
    final pwd = Directory.current;
    try {
      Directory.current = relativeTo;
      final definitions = await _collectDefinitions(exports).toList();
      final analysisContextCollection = AnalysisContextCollection(
        includedPaths: definitions
            .whereType<UnresolvedGlobExport>()
            .map((e) => path.normalize(e.fse.absolute.path))
            .toList(),
      );
      yield* Stream.fromIterable(definitions)
          .asyncMap((d) => _resolveExport(analysisContextCollection, d))
          .where((e) => e != null)
          .cast<SingleExportDefinition>();
    } finally {
      Directory.current = pwd;
    }
  }

  Stream<UnresolvedExport> _collectDefinitions(
    Iterable<ExportDefinition> definitions,
  ) {
    var currentDefinitions = const Stream<UnresolvedExport>.empty();
    for (final definition in definitions) {
      currentDefinitions = _updateDefinitionsWith(
        currentDefinitions,
        definition,
      );
    }
    return currentDefinitions;
  }

  Stream<UnresolvedExport> _updateDefinitionsWith(
    Stream<UnresolvedExport> definitions,
    ExportDefinition definition,
  ) async* {
    switch (definition) {
      case final SingleExportDefinition simple:
        yield* definitions;
        yield UnresolvedExport.single(simple);
      case GlobExportDefinition(
        pattern: ExportPattern(:final pattern, negated: false),
      ):
        yield* definitions;

        final matchedDartFiles = pattern
            .list(followLinks: false)
            .where((e) => e is! Directory)
            .where((e) => path.extension(e.path) == '.dart');
        await for (final file in matchedDartFiles) {
          yield UnresolvedExport.glob(file);
        }
      case GlobExportDefinition(
        pattern: ExportPattern(:final pattern, negated: true),
      ):
        await for (final definition in definitions) {
          // TODO test this
          if (definition.uri.isAbsolute) {
            yield definition;
            continue;
          }

          if (!pattern.matches(definition.uri.toString())) {
            yield definition;
            continue;
          }
        }
    }
  }

  Future<SingleExportDefinition?> _resolveExport(
    AnalysisContextCollection contextCollection,
    UnresolvedExport export,
  ) async {
    switch (export) {
      case UnresolvedSimpleExport(:final export):
        return export;
      case UnresolvedGlobExport(:final fse):
        final normalizedPath = path.normalize(fse.absolute.path);
        final result = await contextCollection
            .contextFor(normalizedPath)
            .currentSession
            .getResolvedUnit(normalizedPath);

        if (result is! ResolvedUnitResult) {
          throw Exception('Could not resolve ${fse.path}: $result');
        }

        if (!result.isLibrary) {
          return null;
        }

        if (_isHidden(result.libraryElement)) {
          return null;
        }

        final anyPublicSymbols = result.libraryElement.children.any(
          (e) => e.isPublic && !_isHidden(e),
        );
        if (!anyPublicSymbols) {
          return null;
        }

        final symbolsToHide = result.libraryElement.children
            .where(_isHidden)
            .map((e) => e.name)
            .nonNulls
            .toList();
        return SingleExportDefinition(
          uri: Uri.parse(path.relative(fse.path)),
          hide: symbolsToHide.isEmpty ? null : ListOrValue.list(symbolsToHide),
        );
    }
  }

  bool _isHidden(Element element) =>
      element.isPublic &&
      (element.metadata.hasInternal ||
          element.metadata.hasVisibleForTesting ||
          element.metadata.hasVisibleForOverriding);
}
