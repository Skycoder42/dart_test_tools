import 'dart:io';

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
}
