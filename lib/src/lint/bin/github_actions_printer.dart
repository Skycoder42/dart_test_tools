import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'console_printer.dart';
import 'package:logging/logging.dart';

@internal
class GithubActionsPrinter extends ConsolePrinter {
  const GithubActionsPrinter([bool warningsAreErrors = false])
      : super(warningsAreErrors);

  @override
  String formatRecord(LogRecord record) {
    final recordLog = super.formatRecord(record);
    final frameDescriptor = _frameDescriptor(record.stackTrace);
    if (record.level >= Level.SEVERE) {
      return '::error$frameDescriptor::$recordLog';
    } else if (record.level >= Level.WARNING) {
      return '::warning$frameDescriptor::$recordLog';
    } else if (record.level >= Level.INFO) {
      return '::notice$frameDescriptor::$recordLog';
    } else {
      return '::debug::$recordLog';
    }
  }

  String _frameDescriptor(StackTrace? stackTrace) {
    if (stackTrace == null) {
      return '';
    }

    final trace = Trace.from(stackTrace);
    for (final frame in trace.frames) {
      if (frame.package == 'dart_test_tools') {
        final fileName = frame.uri.isScheme('file')
            ? frame.uri.toFilePath()
            : frame.uri.toString();
        return ' file=$fileName,line=${frame.line},col=${frame.column},title=${frame.member}';
      }
    }

    return '';
  }
}
