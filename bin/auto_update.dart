import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/auto_update/update_checker.dart';
import 'package:dart_test_tools/src/auto_update/updater.dart';
import 'package:dart_test_tools/src/tools/github.dart';

enum UpdateMode { check, update }

void main(List<String> args) => Github.runZoned(() async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addOption(
          'target',
          abbr: 't',
          valueHelp: 'path',
          help:
              'The <path> of the directory to operate on.\n'
              '(defaults to the value of github.workspace context)',
        )
        ..addOption(
          'mode',
          abbr: 'm',
          allowed: UpdateMode.values.map((m) => m.name),
          defaultsTo: UpdateMode.update.name,
          valueHelp: 'operation',
          help: 'The <operation> to execute.',
        )
        ..addFlag(
          'bump-version',
          abbr: 'b',
          help: 'Use cider to create a changelog message and bump the version',
        )
        ..addOption(
          'report',
          abbr: 'r',
          valueHelp: 'path',
          help: 'Create a markdown report of the update result',
        )
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    final mode = UpdateMode.values.byName(options['mode'] as String);
    final targetPath = options['target'];
    final target = targetPath is String
        ? Directory(targetPath)
        : Github.env.githubWorkspace;

    switch (mode) {
      case UpdateMode.check:
        await const UpdateChecker()(target);
      case UpdateMode.update:
        await Updater(
          bumpVersion: options['bump-version'] as bool,
          reportPath: options['report'] as String?,
        )(target);
    }
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 1;
  }
});
