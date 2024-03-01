import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:dart_test_tools/tools.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

Future<void> main(List<String> args) => Github.runZoned(() async {
      final parser = ArgParser(
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

        await _main(
          minorWidth: int.parse(options['minor'] as String),
          patchWidth: int.parse(options['patch'] as String),
        );
      } on FormatException catch (e) {
        stderr
          ..writeln('Error: ${e.message}\n')
          ..writeln('Usage:')
          ..writeln(parser.usage);
        exitCode = 1;
      }
    });

Future<void> _main({
  required int minorWidth,
  required int patchWidth,
}) async {
  final pubspecFile = File('pubspec.yaml');
  final pubspec = Pubspec.parse(
    await pubspecFile.readAsString(),
    sourceUrl: pubspecFile.uri,
  );

  Github.logInfo('Detected app version as ${pubspec.version}');
  final Version(major: major, minor: minor, patch: patch) = pubspec.version!;

  final buildNumber = _padFilled('major', major, 0) +
      _padFilled('minor', minor, minorWidth) +
      _padFilled('patch', patch, patchWidth);

  Github.logInfo('Generated build number as $buildNumber');

  await Github.env.setOutput('buildNumber', buildNumber);
}

String _padFilled(String name, int number, int width) {
  if (width > 0 && number >= pow(10, width)) {
    throw Exception(
      'Version number does not fit! '
      'Segment $name ($number) has more then $width digits',
    );
  }
  return number.toRadixString(10).padLeft(width, '0');
}
