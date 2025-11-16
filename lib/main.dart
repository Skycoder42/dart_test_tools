import 'dart:async';
import 'dart:io';

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:logging/logging.dart';

import 'gen/package_metadata.dart' as metadata;
import 'src/analyzer_plugin/rules/no_self_package_imports.dart';

// entrypoint for the analyzer plugin
final plugin = DartTestToolsPlugin();

class DartTestToolsPlugin extends Plugin {
  late final _logger = Logger('$DartTestToolsPlugin');

  IOSink? _loggerSink;

  @override
  String get name => metadata.package;

  @override
  Future<void> start() async {
    final logFile = File(
      '/home/sky/repo/dart-packages/dart_test_tools/plugin.log',
    );
    await _loggerSink?.close();
    final loggerSink = _loggerSink = logFile.openWrite(mode: FileMode.append);

    Logger.root
      ..level = Level.ALL
      ..onRecord.listen(
        (r) => _logRecord(loggerSink, r),
        onError: (Object e, StackTrace s) => loggerSink
          ..writeln(e)
          ..writeln(s),
        cancelOnError: false,
      );

    _logger.fine('Started plugin');
  }

  @override
  Future<void> shutDown() async {
    _logger.fine('Shutting down plugin');
    await Future<void>.delayed(Duration.zero);
    await _loggerSink?.flush();
    Logger.root.clearListeners();
    await _loggerSink?.close();
  }

  @override
  void register(PluginRegistry registry) {
    _logger.info('Started analyzer plugin');
    registry.registerWarningRule(NoSelfPackageImports());
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
