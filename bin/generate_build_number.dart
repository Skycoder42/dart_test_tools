import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/ci/build_number_generator.dart';
import 'package:dart_test_tools/src/tools/github.dart';

Future<void> main(List<String> args) => Github.runZoned(() async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addOption(
          'minor',
          abbr: 'm',
          defaultsTo: '2',
          valueHelp: 'width',
          help: 'The <width> of the minor version in the build number.',
        )
        ..addOption(
          'patch',
          abbr: 'p',
          defaultsTo: '2',
          valueHelp: 'width',
          help: 'The <width> of the patch version in the build number.',
        )
        ..addFlag(
          'env',
          abbr: 'E',
          help:
              'Set the BUILD_NUMBER environment variable '
              'instead of the buildNumber output.',
        )
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    const generator = BuildNumberGenerator();
    await generator(
      minorWidth: int.parse(options['minor'] as String),
      patchWidth: int.parse(options['patch'] as String),
      asEnv: options['env'] as bool,
    );
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 1;
  }
});
