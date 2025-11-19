@internal
library;

import 'dart:async';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

import 'auto_export_config.dart';
import 'export_file_writer.dart';
import 'export_resolver.dart';
import 'yaml_serializable.dart';

class AutoExportBuilder {
  final ExportResolver resolver;
  final ExportFileWriter writer;

  const AutoExportBuilder({
    this.resolver = const ExportResolver(),
    this.writer = const ExportFileWriter(),
  });

  Future<void> createExports(File configFile) async {
    final configYaml = await configFile.readAsString();
    final config = checkedYamlDecode(
      configYaml,
      AutoExportConfig.fromJson,
      sourceUrl: configFile.uri,
    )..validate();

    final pubspec = await _loadPubspec();
    for (final target in config.exports) {
      await _createExportTarget(pubspec, target);
    }
  }

  Future<void> createDefaultExports() async {
    final pubspec = await _loadPubspec();
    await _createExportTarget(
      pubspec,
      ExportTarget(
        name: '',
        exports: ListOrValue.value(
          ExportDefinition.glob(ExportPattern(Glob('src/**.dart'))),
        ),
      ),
    );
  }

  Future<Pubspec> _loadPubspec() async {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      throw Exception('No pubspec.yaml found in ${path.current}');
    }
    final pubspecContent = await pubspecFile.readAsString();
    return Pubspec.parse(pubspecContent, sourceUrl: pubspecFile.uri);
  }

  Future<void> _createExportTarget(Pubspec pubspec, ExportTarget target) async {
    final outName = target.name.isEmpty ? pubspec.name : target.name;

    final outFile = File(path.join('lib', path.setExtension(outName, '.dart')));

    final exports = await resolver
        .resolveExports(outFile.parent, target.exports)
        .toList();

    await writer.writeExport(outFile, exports);
  }
}
