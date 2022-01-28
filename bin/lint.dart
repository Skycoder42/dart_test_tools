import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> rawArgs) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(stdout.writeln);

  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      defaultsTo: Directory.current.path,
      help: 'The path of the package to scan.',
    )
    ..addMultiOption(
      'include-paths',
      abbr: 'i',
      help: 'Additional paths to be included into the analysis context.',
    )
    ..addMultiOption(
      'exclude-paths',
      abbr: 'e',
      help: 'Additional paths to be excluded from the analysis context.',
    )
    ..addOption(
      'log-level',
      abbr: 'l',
      allowed: Level.LEVELS.map((level) => level.name),
      defaultsTo: Level.INFO.name,
      help: 'Set the log-level for messages to be printed.',
      allowedHelp: {
        for (var level in Level.LEVELS)
          level.name:
              'Logs all messages with a severity of at least ${level.value}.',
      },
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help',
    );
}
