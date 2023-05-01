// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:test/test.dart';

typedef TypeMatcherCb<T> = TypeMatcher<T> Function(TypeMatcher<T> match);

@isTest
void customLintTest(
  String description, {
  Map<String, String> files = const {},
  required int expectedExitCode,
  required Matcher expectedOutput,
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) =>
    test(
      description,
      () async {
        final dartDir = await _setup();
        for (final entry in files.entries) {
          final file = File.fromUri(dartDir.uri.resolve(entry.key));
          await file.parent.create(recursive: true);
          await file.writeAsString(entry.value);
        }

        await _expectDart(
          const ['run', 'custom_lint'],
          expectedExitCode: expectedExitCode,
          expectedOutput: expectedOutput,
          workingDirectory: dartDir,
        );

        await _cleanup(dartDir);
      },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry,
    );

Future<Directory> _setup() async {
  final testDir = await Directory.systemTemp.createTemp();
  printOnFailure('Using temporary directory: $testDir');
  await _runDart(
    const [
      'create',
      '--template',
      'package-simple',
      'dart_test_tools_integration_test',
    ],
    testDir,
  );

  final dartDir = Directory.fromUri(
    testDir.uri.resolve('dart_test_tools_integration_test'),
  );

  await _runDart([
    'pub',
    'add',
    'meta',
    'dev:custom_lint',
    'dev:dart_test_tools:{"path":"${Directory.current.path}"}',
  ], dartDir);

  await Directory.fromUri(
    dartDir.uri.resolve('lib'),
  ).delete(recursive: true);
  await Directory.fromUri(
    dartDir.uri.resolve('test'),
  ).delete(recursive: true);

  return dartDir;
}

Future<void> _cleanup(Directory dartDir) async {
  await dartDir.parent.delete(recursive: true);
}

Future<void> _expectDart(
  List<String> arguments, {
  required int expectedExitCode,
  required Matcher expectedOutput,
  Directory? workingDirectory,
}) async {
  final dartProc = await Process.start(
    'dart',
    arguments,
    workingDirectory: workingDirectory?.path,
  );
  dartProc.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((event) => print('dart ${arguments.join(' ')}: $event'));

  await expectLater(
    dartProc.stdout.transform(utf8.decoder).transform(const LineSplitter()),
    expectedOutput,
  );
  await expectLater(dartProc.exitCode, completion(expectedExitCode));
}

Future<void> _runDart(
  List<String> arguments, [
  Directory? workingDirectory,
]) async {
  final dartProc = await Process.start(
    'dart',
    arguments,
    workingDirectory: workingDirectory?.path,
  );
  dartProc.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((event) => print('dart ${arguments.join(' ')}: $event'));
  dartProc.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((event) => printOnFailure('dart ${arguments.join(' ')}: $event'));

  await expectLater(dartProc.exitCode, completion(0));
}
