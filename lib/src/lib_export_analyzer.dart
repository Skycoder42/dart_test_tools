import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'analyzer_base.dart';

Future<void> main() async {
  Logger.root.onRecord.listen(stdout.writeln);
  Logger.root.level = Level.FINEST;

  final analyzer = LibExportAnalyzer(
    contextCollection: AnalysisContextCollection(
      includedPaths: [
        path.canonicalize(
          'C:/Users/felix.barz/repos/other/libsodium_dart_bindings/packages/sodium',
        ),
      ],
    ),
    logger: Logger('LibExportAnalyzer'),
  );

  await analyzer.runAnalysis();
}

class LibExportAnalyzer extends AnalyzerBase {
  const LibExportAnalyzer({
    required AnalysisContextCollection contextCollection,
    required Logger logger,
  }) : super(
          contextCollection: contextCollection,
          logger: logger,
        );

  @override
  Future<bool> runAnalysis() async {
    for (final context in contextCollection.contexts) {
      final libDir = context.contextRoot.lib;
      final srcDir = context.contextRoot.src;

      final exports = <String>{};
      // final sources = <String>{};

      for (final path in context.contextRoot.analyzedFiles()) {
        if (!_isDartFile(path)) {
          logSkipFile(path, 'not a dart file');
        }

        if (srcDir.contains(path)) {
        } else if (libDir.contains(path)) {
          exports.addAll(await _scanForExports(context, path).toList());
        } else {
          logSkipFile(path, 'not a package library file');
        }
      }
    }

    return false;
  }

  bool _isDartFile(String path) => path.endsWith('.dart');

  Stream<String> _scanForExports(
    AnalysisContext context,
    String path, {
    Level logLevel = Level.INFO,
  }) async* {
    final unit = await analyzeFile(context, path);
    if (unit == null) {
      return;
    }

    logger.log(logLevel, 'Scanning $path for exports...');
    yield* _getExports(context, unit);
  }

  Stream<String> _getExports(
    AnalysisContext context,
    CompilationUnit compilationUnit,
  ) async* {
    final pubspec = context.contextRoot.pubspec;
    final srcDir = context.contextRoot.src;

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
          logger.warning(
            'Unable to resolve source of directive $exportDirective',
          );
          continue;
        }

        // skip non package sources
        final sourceUri = exportSource.uri;
        if (!sourceUri.isScheme('package')) {
          _logSkipExport(sourceUri, 'not a package export');
          continue;
        }

        // skip package exports of different packages
        final exportPackageName = sourceUri.pathSegments.first;
        if (exportPackageName != pubspec.name) {
          _logSkipExport(sourceUri, 'not an export of this package');
          continue;
        }

        final sourcePath = exportSource.fullName;
        if (!srcDir.contains(sourcePath)) {
          _logSkipExport(sourceUri, 'not a src file');
          continue;
        }

        logger.fine('Found exported source $sourceUri');
        yield sourcePath;

        try {
          yield* _scanForExports(
            contextCollection.contextFor(sourcePath),
            sourcePath,
            logLevel: Level.FINER,
          );
          // ignore: avoid_catching_errors
        } on StateError catch (error, stackTrace) {
          logger.warning(
            'Unabled to scan $sourcePath for further exports',
            error,
            stackTrace,
          );
        }
      }
    }
  }

  void _logSkipExport(Uri uri, String reason) =>
      logger.finest('Skipping export $uri, $reason');
}
