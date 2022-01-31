import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:args/args.dart';
import 'package:dart_test_tools/dart_test_tools.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

class _LogPrinter {
  bool _warningsAreErrors = false;
  bool _hasWarnings = false;

  bool get warningsAreErrors => _warningsAreErrors;
  set warningsAreErrors(bool value) {
    _warningsAreErrors = value;
    if (_hasWarnings) {
      exitCode = exitCode == 1 ? 1 : 2;
    }
  }

  void call(LogRecord record) {
    stdout.writeln(_formatRecord(record));

    if (record.level >= Level.SEVERE) {
      exitCode = 1;
    } else if (record.level >= Level.WARNING) {
      _hasWarnings = true;
      if (_warningsAreErrors) {
        exitCode = exitCode == 1 ? 1 : 2;
      }
    }
  }

  String _formatRecord(LogRecord record) {
    final recordLog = _formatPlainRecord(record);
    if (!stdout.supportsAnsiEscapes) {
      return _formatPlainRecord(record);
    } else {
      if (record.level >= Level.SHOUT) {
        return _colored(recordLog, 35);
      } else if (record.level >= Level.SEVERE) {
        return _colored(recordLog, 31);
      } else if (record.level >= Level.WARNING) {
        return _colored(recordLog, 33);
      } else if (record.level >= Level.INFO) {
        return _colored(recordLog, 34);
      } else if (record.level >= Level.CONFIG) {
        return _colored(recordLog, 36);
      } else if (record.level >= Level.FINE) {
        return _colored(recordLog, 32);
      } else if (record.level >= Level.FINER) {
        return _colored(recordLog, 37, 40);
      } else if (record.level >= Level.FINEST) {
        return _colored(recordLog, 30, 47);
      } else {
        return recordLog;
      }
    }
  }

  String _formatPlainRecord(LogRecord record) {
    final logMessag = StringBuffer()..write('[${record.level}] ');
    if (record.loggerName.isNotEmpty) {
      logMessag.write('${record.loggerName}: ');
    }
    logMessag.write(record.message);
    if (record.error != null) {
      logMessag.write(' ${record.error}');
    }
    if (record.stackTrace != null) {
      logMessag.write('\n${record.stackTrace}');
    }
    return logMessag.toString();
  }

  String _colored(String message, int foreground, [int? background]) {
    final color =
        background != null ? '$foreground;$background' : foreground.toString();
    return '\x1b[${color}m$message\x1b[0m';
  }
}

Future<void> main(List<String> rawArgs) async {
  final printer = _LogPrinter();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(printer);

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
      help: 'Failes with exit code 2 if any warnings occur.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help.',
    );

  try {
    final args = parser.parse(rawArgs);
    for (final arg in args.options) {
      Logger.root.config('$arg: ${args[arg]}');
    }

    if (args['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    printer.warningsAreErrors = args['fatal-warnings'] as bool;
    final levelName = args['log-level'] as String;
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == levelName,
    );

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
