import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/aur.dart';

Future<void> main(List<String> rawArgs) async {
  final parser = ArgParser(
    usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
  )
    ..addOption(
      'input',
      abbr: 'i',
      defaultsTo: Directory.current.path,
      valueHelp: 'directory',
      help:
          'The source <directory> to the dart package that should be packaged.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: Directory.current.uri.resolve('aur').toFilePath(),
      valueHelp: 'directory',
      help: 'The target <directory> where the generated PKGBUILD and other '
          'files should be placed. Typically, this is the already checked out '
          'git repository. See '
          'https://wiki.archlinux.org/title/AUR_submission_guidelines for '
          'additional information.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help.',
    );

  try {
    final args = parser.parse(rawArgs);

    if (args['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    const generator = PkgBuildGenerator();
    await generator.generatePkgbuild(
      sourceDirectory: Directory(args['input'] as String),
      aurDirectory: Directory(args['output'] as String),
    );
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 3;
  }
}
