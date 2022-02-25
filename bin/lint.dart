import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:args/args.dart';
import 'package:dart_test_tools/dart_test_tools.dart';
import 'package:dart_test_tools/src/lint/bin/console_printer.dart';
import 'package:dart_test_tools/src/lint/bin/github_actions_printer.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

Future<void> main(List<String> rawArgs) async {
  final linters = <Linter>[
    LibExportLinter(),
    TestImportLinter(),
  ];

  final parser = ArgParser()
    ..addSeparator('Lintings')
    ..addMultiOption(
      'linter',
      aliases: ['analyzer'],
      abbr: 'a',
      allowed: linters.map((l) => l.name),
      defaultsTo: linters.map((l) => l.name),
      help: '',
      valueHelp: 'linter',
      allowedHelp: {
        for (final linter in linters) linter.name: linter.description
      },
    )
    ..addSeparator('Common Options')
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
      'fatal-warnings',
      abbr: 'W',
      help: 'Fails with exit code 2 if any warnings occur.',
    )
    ..addFlag(
      'actions-printer',
      help: 'Enables the GitHub Actions log printer',
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

    final warningsAreErrors = args['fatal-warnings'] as bool;
    final printer = (args['actions-printer'] as bool)
        ? GithubActionsPrinter(warningsAreErrors)
        : ConsolePrinter(warningsAreErrors);

    final levelName = args['log-level'] as String;
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == levelName,
    );

    // ignore: unawaited_futures
    Logger.root.onRecord.pipe(printer);

    for (final arg in args.options) {
      Logger.root.config('$arg: ${args[arg]}');
    }

    final selectedLinters = args['linter'] as List<String>;
    final contextCollection = _createContextCollection(args);
    for (final context in contextCollection.contexts) {
      Logger.root.config(
        'Found context: ${context.contextRoot.root} '
        '(Workspace: ${context.contextRoot.workspace.root})',
      );
    }

    for (final linter in linters) {
      if (selectedLinters.contains(linter.name)) {
        linter.contextCollection = contextCollection;
        if (!await _runLinter(linter)) {
          exitCode = 1;
        }
      }
    }
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 3;
  }
}

AnalysisContextCollection _createContextCollection(ArgResults args) =>
    AnalysisContextCollection(
      includedPaths: [
        canonicalize(args['path'] as String),
        ...args['include-paths'] as List<String>,
      ],
      excludedPaths: args['exclude-paths'] as List<String>,
    );

Future<bool> _runLinter(Linter linter) => linter.call().map((result) {
      result.when(
        accepted: (resultLocation) =>
            linter.logger.finer(resultLocation.createLogMessage('OK')),
        rejected: (reason, resultLocation) => linter.logger
            .info(resultLocation.createLogMessage('REJECTED: $reason')),
        skipped: (reason, resultLocation) => linter.logger
            .fine(resultLocation.createLogMessage('SKIPPED: $reason')),
        failure: (error, stackTrace, resultLocation) => linter.logger.severe(
          resultLocation.createLogMessage('FAILURE: $error'),
          null,
          stackTrace,
        ),
      );
      return result;
    }).fold(
      true,
      (previous, element) =>
          previous &&
          element.maybeWhen(
            accepted: (_) => true,
            skipped: (_, __) => true,
            orElse: () => false,
          ),
    );
