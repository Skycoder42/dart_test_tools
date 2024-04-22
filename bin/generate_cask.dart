import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/cask/cask_generator.dart';
import 'package:dart_test_tools/src/tools/github.dart';

Future<void> main(List<String> args) => Github.runZoned(() async {
      final parser = ArgParser(
        usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
      )
        ..addOption(
          'input',
          abbr: 'i',
          defaultsTo: Directory.current.path,
          valueHelp: 'directory',
          help: 'The source <directory> to the app that should be packaged.',
        )
        ..addOption(
          'output',
          abbr: 'o',
          mandatory: true,
          valueHelp: 'directory',
          help: 'The target <directory> where the generated Cask script should '
              'be placed.',
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

        await const CaskGenerator()(
          inDir: Directory(options['input'] as String),
          outDir: Directory(options['output'] as String),
        );
      } on FormatException catch (e) {
        stderr
          ..writeln('Error: ${e.message}\n')
          ..writeln('Usage:')
          ..writeln(parser.usage);
        exitCode = 3;
      }
    });
