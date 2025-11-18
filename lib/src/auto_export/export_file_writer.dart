@internal
library;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';

import 'auto_export_config.dart';

class ExportFileWriter {
  const ExportFileWriter();

  Future<void> writeExport(
    File file,
    List<SingleExportDefinition> exports,
  ) async {
    final packageExports = exports
        .where((e) => e.uri.isScheme('package'))
        .sortedBy((e) => e.uri.toString());
    final relativeExports = exports
        .where((e) => !e.uri.isScheme('package'))
        .sortedBy((e) => e.uri.toString());

    final codeBuffer = StringBuffer();
    for (final definition in packageExports) {
      _writeExport(codeBuffer, definition);
    }
    codeBuffer.writeln();
    for (final definition in relativeExports) {
      _writeExport(codeBuffer, definition);
    }

    final formattedCode = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(codeBuffer.toString(), uri: file.uri);

    await file.writeAsString(formattedCode);
  }

  void _writeExport(StringSink sink, SingleExportDefinition d) {
    sink
      ..write("export '")
      ..write(d.uri)
      ..write("'");

    if (d.configurations case ExportConfigurations(:final configurations)) {
      for (final configuration in configurations) {
        _writeConfiguration(sink, configuration);
      }
    }

    if (d.show case final show?) {
      _writeCombinator(sink, 'show', show);
    }

    if (d.hide case final hide?) {
      _writeCombinator(sink, 'hide', hide);
    }

    sink.writeln(';');
  }

  void _writeConfiguration(StringSink sink, ExportConfiguration configuration) {
    sink
      ..write(' if(')
      ..write(configuration.define);

    if (configuration.equals case final equals?) {
      final containsSingleQuote = equals.contains("'");
      final containsDoubleQuote = equals.contains('"');
      final quotes = switch ((containsSingleQuote, containsDoubleQuote)) {
        (true, true) => "'''",
        (true, _) => '"',
        _ => "'",
      };
      sink
        ..write(' == r')
        ..write(quotes)
        ..write(equals)
        ..write(quotes);
    }

    sink
      ..write(") '")
      ..write(configuration.uri)
      ..write("'");
  }

  void _writeCombinator(
    StringSink sink,
    String name,
    Iterable<String> identifiers,
  ) {
    sink
      ..write(' ')
      ..write(name)
      ..write(' ')
      ..writeAll(identifiers, ', ');
  }
}
