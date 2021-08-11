import 'dart:io';

import 'package:pubspec_parse/pubspec_parse.dart';

class ChildErrorException implements Exception {
  final int exitCode;

  ChildErrorException(this.exitCode);
}

class Runner {
  Future<void> call(
    String executable,
    List<String> arguments, {
    bool runInShell = false,
  }) async {
    stdout.writeln('> Running $executable ${arguments.join(' ')}');
    final process = await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.inheritStdio,
      runInShell: runInShell,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw ChildErrorException(exitCode);
    }
  }

  Future<void> dart(List<String> arguments) => call('dart', arguments);

  Future<void> flutter(List<String> arguments) => call(
        'flutter',
        arguments,
        runInShell: Platform.isWindows,
      );

  Future<void> pub(List<String> arguments) async {
    final pubspecFile = File('pubspec.yaml');
    final pubspec = Pubspec.parse(
      await pubspecFile.readAsString(),
      sourceUrl: pubspecFile.uri,
    );

    final isFlutter = pubspec.dependencies.containsKey('flutter');
    return isFlutter
        ? flutter(['pub', ...arguments])
        : dart(['pub', ...arguments]);
  }
}
