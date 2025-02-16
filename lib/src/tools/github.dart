import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'io.dart';

class _GithubEnv {
  const _GithubEnv();

  Directory get runnerTemp {
    final runnerTemp = Platform.environment['RUNNER_TEMP'];
    return runnerTemp != null ? Directory(runnerTemp) : Directory.systemTemp;
  }

  Directory get runnerToolCache {
    final runnerToolCache = Platform.environment['RUNNER_TOOL_CACHE'];
    return runnerToolCache != null ? Directory(runnerToolCache) : runnerTemp;
  }

  String? get runnerOs => Platform.environment['RUNNER_OS'];

  String? get runnerArch => Platform.environment['RUNNER_ARCH'];

  Directory get githubWorkspace {
    final githubWorkspace = Platform.environment['GITHUB_WORKSPACE'];
    return githubWorkspace != null
        ? Directory(githubWorkspace)
        : Directory.current.subDir('../..');
  }

  Future<void> setOutput(
    String name,
    Object? value, {
    bool multiline = false,
    bool asEnv = false,
  }) async {
    final outKey = asEnv ? 'GITHUB_ENV' : 'GITHUB_OUTPUT';
    final outputFilePath = Platform.environment[outKey];
    if (outputFilePath == null) {
      throw Exception('Cannot set output! $outKey env var is not set');
    }

    final outputFile = File(outputFilePath);
    if (multiline) {
      await outputFile.writeAsString(
        '$name<<EOF\n$value\nEOF\n',
        mode: FileMode.append,
      );
    } else {
      await outputFile.writeAsString('$name=$value\n', mode: FileMode.append);
    }
  }

  Future<void> addPath(Directory directory) async {
    final outputFilePath = Platform.environment['GITHUB_PATH'];
    if (outputFilePath == null) {
      throw Exception('Cannot set output! GITHUB_PATH env var is not set');
    }

    final resolvedPath = await directory.resolveSymbolicLinks();
    final outputFile = File(outputFilePath);
    await outputFile.writeAsString('$resolvedPath\n', mode: FileMode.append);
  }
}

abstract base class Github {
  Github._();

  static const env = _GithubEnv();

  static void logDebug(String message) => print('::debug::$message');

  static void logInfo(String message) => print('Info: $message');

  static void logNotice(String message) => print('::notice::$message');

  static void logWarning(String message) => print('::warning::$message');

  static void logError(String message) => print('::error::$message');

  static T logGroup<T>(String title, T Function() body) {
    print('::group::$title');
    try {
      return body();
    } finally {
      print('::endgroup::');
    }
  }

  static Future<T> logGroupAsync<T>(
    String title,
    FutureOr<T> Function() body,
  ) async {
    print('::group::$title');
    try {
      return await body();
    } finally {
      print('::endgroup::');
    }
  }

  static Future<void> runZoned(
    FutureOr<void> Function() main, {
    bool setExitCode = true,
  }) async => runZonedGuarded(main, (error, stack) {
    logError(error.toString());
    logGroup('Stack-Trace', () => print(stack));
    if (setExitCode) {
      exitCode = 1;
    }
  });

  static Future<int> exec(
    String executable,
    List<String> arguments, {
    Directory? workingDirectory,
    Map<String, String>? environment,
    bool runInShell = false,
    int? expectedExitCode = 0,
  }) async {
    print('[command] $executable ${arguments.join(' ')}');
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory?.path,
      environment: environment,
      runInShell: runInShell,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;
    if (expectedExitCode != null && exitCode != expectedExitCode) {
      throw Exception('Process $executable failed with exit code: $exitCode');
    }
    return exitCode;
  }

  static Stream<String> execLines(
    String executable,
    List<String> arguments, {
    Directory? workingDirectory,
    Map<String, String>? environment,
    bool runInShell = false,
    int? expectedExitCode = 0,
    void Function(String message) onStderr = logWarning,
  }) async* {
    print('[command] $executable ${arguments.join(' ')}');
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory?.path,
      environment: environment,
      runInShell: runInShell,
    );

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onStderr);

    yield* process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final exitCode = await process.exitCode;
    if (expectedExitCode != null && exitCode != expectedExitCode) {
      throw Exception('Process $executable failed with exit code: $exitCode');
    }
  }
}
