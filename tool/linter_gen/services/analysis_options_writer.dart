import 'dart:io';

import 'package:yaml_writer/yaml_writer.dart';

import '../models/analysis_options.dart';
import '../models/analysis_options_ref.dart';

class AnalysisOptionsWriter {
  final YamlWriter yamlWriter;

  AnalysisOptionsWriter({
    required this.yamlWriter,
  });

  Future<void> saveAnalysisOptions(
    AnalysisOptionsRef target,
    AnalysisOptions analysisOptions,
  ) async {
    final analysisOptionsPath = target.when(
      local: (path) => path,
      package: (_, __) => throw Exception('Cannot save options to a package'),
    );

    final file = File(analysisOptionsPath);
    await file.parent.create(recursive: true);

    final sink = file.openWrite();
    try {
      _writeRecursive(sink, 0, analysisOptions);
    } finally {
      await sink.close();
    }
  }

  void _writeRecursive(IOSink sink, int level, dynamic data) {
    late final dynamic encodedData;
    try {
      // ignore: avoid_dynamic_calls
      encodedData = data.toJson();
      // ignore: avoid_catching_errors
    } on NoSuchMethodError {
      encodedData = data;
    }

    if (encodedData is Map) {
      if (level > 0) {
        sink.writeln();
      }

      for (final entry in encodedData.entries) {
        sink.write('  ' * level);
        final key = entry.key.toString();
        if (key.startsWith('#')) {
          sink.writeln(entry.key);
        } else {
          sink.write('$key: ');
          _writeRecursive(sink, level + 1, entry.value);
        }
      }
    } else if (encodedData is List) {
      if (level > 0) {
        sink.writeln();
      }

      for (final element in encodedData) {
        sink.write('  ' * level);
        if (element is String && element.startsWith('#')) {
          sink.writeln(element);
        } else {
          sink.write('- ');
          _writeRecursive(sink, level + 1, element);
        }
      }
    } else {
      sink.writeln(encodedData);
    }
  }
}
