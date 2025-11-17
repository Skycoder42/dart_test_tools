import 'dart:async';
import 'dart:io';

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'gen/package_metadata.dart' as metadata;
import 'src/analyzer_plugin/no_self_package_imports.dart';

// entrypoint for the analyzer plugin
final plugin = DartTestToolsPlugin();

class DartTestToolsPlugin extends Plugin {
  late final _logger = Logger('$DartTestToolsPlugin');

  IOSink? _loggerSink;

  @override
  String get name => metadata.package;

  @override
  Future<void> start() async => await _setUpLogging();

  @override
  Future<void> shutDown() async => await _tearDownLogging();

  @override
  void register(PluginRegistry registry) {
    _logger.info('Started analyzer plugin');
    registry.registerWarningRule(NoSelfPackageImports());
  }

  Future<void> _setUpLogging() async {
    final logLevelStr = Platform.environment['DART_TEST_TOOLS_PLUGIN_LOG_LEVEL']
        ?.toUpperCase();
    final logLevel = Level.LEVELS
        .where((l) => l.name == logLevelStr)
        .firstOrNull;

    if (logLevel == null) {
      return;
    }

    final loggingPath =
        Platform.environment['DART_TEST_TOOLS_PLUGIN_LOG_PATH'] ??
        path.join(path.current, 'plugin.log');
    final logFile = File(loggingPath);
    await _loggerSink?.close();
    final loggerSink = _loggerSink = logFile.openWrite(mode: FileMode.append);

    Logger.root
      ..level = logLevel
      ..onRecord.listen(
        (r) => _logRecord(loggerSink, r),
        onError: (Object e, StackTrace s) => loggerSink
          ..writeln(e)
          ..writeln(s),
        cancelOnError: false,
      );

    _logger.fine('Started plugin');
  }

  Future<void> _tearDownLogging() async {
    _logger.fine('Shutting down plugin');
    await _loggerSink?.flush();
    Logger.root.clearListeners();
    await _loggerSink?.close();
  }

  void _logRecord(StringSink sink, LogRecord record) {
    sink
      ..write(record.time.toIso8601String().substring(0, 19))
      ..write(' ')
      ..writeln(record);
    if (record.error case final error?) {
      sink
        ..write('>>>> ')
        ..writeln(error);
    }
    if (record.stackTrace case final stackTrace?) {
      sink
        ..write('>>>> ')
        ..writeln(stackTrace);
    }
  }
}
