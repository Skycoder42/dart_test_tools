import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

@internal
class ConsolePrinter implements StreamConsumer<LogRecord> {
  final bool _warningsAreErrors;

  const ConsolePrinter([this._warningsAreErrors = false]);

  @override
  Future<void> addStream(Stream<LogRecord> stream) =>
      stream.listen(_handleLogRecord).asFuture();

  @override
  Future<void> close() => Future.value(null);

  void _handleLogRecord(LogRecord record) {
    stdout.writeln(formatRecord(record));

    if (record.level >= Level.SEVERE) {
      exitCode = 1;
    } else if (record.level >= Level.WARNING) {
      if (_warningsAreErrors) {
        exitCode = exitCode == 1 ? 1 : 2;
      }
    }
  }

  @protected
  String formatRecord(LogRecord record) {
    final recordLog = formatPlainRecord(record);
    if (!stdout.supportsAnsiEscapes) {
      return recordLog;
    } else {
      return applyColor(recordLog, record.level);
    }
  }

  @protected
  String formatPlainRecord(LogRecord record) {
    final logMessage = StringBuffer()..write('[${record.level}] ');
    if (record.loggerName.isNotEmpty) {
      logMessage.write('${record.loggerName}: ');
    }
    logMessage.write(record.message);
    if (record.error != null) {
      logMessage.write(' ${record.error}');
    }
    if (record.stackTrace != null) {
      logMessage.write('\n${record.stackTrace}');
    }
    return logMessage.toString();
  }

  @protected
  String applyColor(String message, Level level) {
    if (level >= Level.SHOUT) {
      return _colored(message, 35);
    } else if (level >= Level.SEVERE) {
      return _colored(message, 31);
    } else if (level >= Level.WARNING) {
      return _colored(message, 33);
    } else if (level >= Level.INFO) {
      return _colored(message, 34);
    } else if (level >= Level.CONFIG) {
      return _colored(message, 36);
    } else if (level >= Level.FINE) {
      return _colored(message, 32);
    } else if (level >= Level.FINER) {
      return _colored(message, 37, 40);
    } else if (level >= Level.FINEST) {
      return _colored(message, 30, 47);
    } else {
      return message;
    }
  }

  String _colored(String message, int foreground, [int? background]) {
    final color =
        background != null ? '$foreground;$background' : foreground.toString();
    return '\x1b[${color}m$message\x1b[0m';
  }
}
