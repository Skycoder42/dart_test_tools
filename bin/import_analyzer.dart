import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:args/args.dart';
import 'package:dart_test_tools/src/import_analyzers/relative_import_analyzer.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

Future<void> main(List<String> rawArgs) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(stdout.writeln);

  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      mandatory: true,
      help: 'The path of the package to scan.',
    )
    ..addOption(
      'name',
      abbr: 'n',
      mandatory: true,
      help: 'The name of the package to be scanned.',
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

  try {
    final args = parser.parse(rawArgs);
    if (args['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    final levelName = args['log-level'] as String;
    Logger.root.level = Level.LEVELS.firstWhere(
      (level) => level.name == levelName,
    );

    final path = canonicalize(args['path'] as String);
    final name = args['name'] as String;
    final includePaths = args['include-paths'] as List<String>;
    final excludePaths = args['exclude-paths'] as List<String>;

    final analyzer = RelativeImportAnalyzer(
      packageRoot: path,
      packageName: name,
      contextCollection: AnalysisContextCollection(
        includedPaths: [
          path,
          ...includePaths,
        ],
        excludedPaths: excludePaths,
      ),
    );

    final succeeded = await analyzer.runAnalysis();
    exitCode = succeeded ? 0 : 1;
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
  }
}
