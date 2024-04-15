import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/flatpak/export_xml_changelog/export_xml_changelog.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser(
    usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
  )
    ..addOption(
      'output',
      abbr: 'o',
      mandatory: true,
      valueHelp: 'path',
      help: 'The path of the file to write the changelog to.',
    )
    ..addFlag(
      'metainfo',
      defaultsTo: true,
      help: 'Assumes the target file is a metainfo.xml file. '
          'In this case, the changelog is written as a child element of the '
          'component. Otherwise the file is overwritten as standalone '
          'release information file.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help.',
    );

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    const exportXmlChangelog = ExportXmlChangelog();
    await exportXmlChangelog(
      outFile: File(options['output'] as String),
      isMetadataXml: options['metainfo'] as bool,
    );
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 1;
  }
}
