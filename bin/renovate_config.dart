import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/renovate/global_config.dart';
import 'package:dart_test_tools/src/renovate/renovate_preset.dart';
import 'package:dart_test_tools/src/tools/github.dart';

void main(List<String> args) => Github.runZoned(() async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addOption(
          'repository',
          abbr: 'r',
          valueHelp: 'path',
          help:
              'The <path> of a checkout of the repository to compute the '
              'package rules for. The checkout gets modified. Flutter SDK '
              'compatibility is enforced if its Renovate config extends the '
              'library preset, but not for the application preset.',
        )
        ..addOption(
          'output',
          abbr: 'o',
          valueHelp: 'path',
          help: 'The <path> of the file to write the global config to.',
        )
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    final repository = options['repository'] as String?;
    if (repository == null) {
      throw const FormatException('Option repository is mandatory.');
    }
    final output = options['output'] as String?;
    if (output == null) {
      throw const FormatException('Option output is mandatory.');
    }

    final repositoryDir = Directory(repository);
    final config = await GlobalConfig(
      repository: repositoryDir,
      preset: await RenovatePreset.detect(repositoryDir),
    ).build();

    await File(output).writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
      flush: true,
    );
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 1;
  }
});
