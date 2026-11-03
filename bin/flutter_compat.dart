import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/flutter_compat/flutter_compat.dart';
import 'package:dart_test_tools/src/tools/github.dart';

void main(List<String> args) => Github.runZoned(() async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addOption(
          'directory',
          abbr: 'd',
          valueHelp: 'dir',
          defaultsTo: '.',
          help:
              'The <dir> of the package or workspace to check. All published '
              'dart packages of the workspace are checked.',
        )
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    final result = await FlutterCompat(
      directory: Directory(options['directory'] as String),
    )();
    exitCode = switch (result) {
      .compatible || .nothingToCheck => 0,
      .incompatible => 1,
    };
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 2;
  } on FlutterCompatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exitCode = 2;
  }
});
