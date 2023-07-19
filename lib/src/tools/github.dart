import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/dart_test_tools.dart';

class _GithubEnv {
  const _GithubEnv();

  Directory get runnerTemp {
    final runnerTemp = Platform.environment['RUNNER_TEMP'];
    return runnerTemp != null ? Directory(runnerTemp) : Directory.systemTemp;
  }

  Directory get githubWorkspace {
    final githubWorkspace = Platform.environment['GITHUB_WORKSPACE'];
    return githubWorkspace != null
        ? Directory(githubWorkspace)
        : Directory.current.subDir('../..');
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
  }) async =>
      runZonedGuarded(main, (error, stack) {
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
        .transform(LineSplitter())
        .listen(onStderr);

    yield* process.stdout.transform(utf8.decoder).transform(LineSplitter());

    final exitCode = await process.exitCode;
    if (expectedExitCode != null && exitCode != expectedExitCode) {
      throw Exception('Process $executable failed with exit code: $exitCode');
    }
  }
}
