import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/flatpak/repo_init/repo_init.dart';

Future<void> main(List<String> args) async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addSeparator('Repository generation')
        ..addOption(
          'repo',
          abbr: 'r',
          valueHelp: 'path',
          help:
              'Path to the repository that should be initialized. '
              'Must be an initialized github repository.',
          mandatory: true,
        )
        ..addOption(
          'gpg-key',
          abbr: 'k',
          valueHelp: 'key-id',
          help: 'The Key-ID of the GPG key to sign the repository with.',
          mandatory: true,
        )
        ..addFlag(
          'update',
          abbr: 'U',
          help:
              'Update configuration of an existing repository '
              'instead of creating a new one.',
        )
        ..addSeparator('Metadata configuration')
        ..addOption(
          'metainfo',
          abbr: 'm',
          valueHelp: 'path',
          help:
              'Path to the metainfo.xml to generate the flatpakrepo file from.',
          mandatory: true,
        )
        ..addOption(
          'icon',
          abbr: 'i',
          valueHelp: 'path',
          help: 'Path to an icon file to be used as repository icon.',
        )
        ..addSeparator('Other')
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    const repoInit = RepoInit();
    final iconPath = options['icon'] as String?;
    await repoInit(
      repo: Directory(options['repo'] as String),
      metaInfo: File(options['metainfo'] as String),
      gpgKeyId: options['gpg-key'] as String,
      icon: iconPath != null ? File(iconPath) : null,
      update: options['update'] as bool,
    );
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 1;
  }
}
