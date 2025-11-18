@internal
library;

import 'dart:async';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'auto_export_config.dart';
import 'export_file_writer.dart';
import 'export_resolver.dart';

class AutoExportBuilder {
  final ExportResolver resolver;
  final ExportFileWriter writer;

  AutoExportBuilder(this.resolver, {required this.writer});

  Future<void> createExports(File configFile) async {
    final configYaml = await configFile.readAsString();
    final config = checkedYamlDecode(
      configYaml,
      AutoExportConfig.fromJson,
      sourceUrl: configFile.uri,
    )..validate();

    for (final target in config.exports) {
      await _createExportTarget(target);
    }
  }

  Future<void> _createExportTarget(ExportTarget target) async {
    final outFile = File(
      path.join('lib', path.setExtension(target.name, '.dart')),
    );

    final exports = await resolver
        .resolveExports(outFile.parent, target.exports)
        .toList();

    await writer.writeExport(outFile, exports);
  }
}
