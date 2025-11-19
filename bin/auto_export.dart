import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/auto_export/auto_export_builder.dart';

Future<void> main(List<String> args) async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addOption(
          'working-directory',
          abbr: 'd',
          valueHelp: 'path',
          help:
              'The <path> where to run the exporter. Must be the package root '
              'directory that contains the pubspec.yaml.',
          defaultsTo: Directory.current.path,
        )
        ..addOption(
          'target',
          abbr: 't',
          valueHelp: 'path',
          help:
              'The <path> of exports configuration file. If not specified and '
              'the default file does not exist, a standard export will be '
              'created. This will simply be a file named after the package '
              'containing all exportable files in the src/ directory.',
          defaultsTo: 'lib/exports.yaml',
        )
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    Directory.current = options['working-directory'] as String;

    const exporter = AutoExportBuilder();

    final configPath = options['target'] as String;
    final configFile = File(configPath);
    if (configFile.existsSync()) {
      await exporter.createExports(configFile);
    } else if (!options.wasParsed('target')) {
      // assume default config of all src files
      await exporter.createDefaultExports();
    } else {
      throw FormatException('Config file not found: $configPath');
    }
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 1;
  }
}
