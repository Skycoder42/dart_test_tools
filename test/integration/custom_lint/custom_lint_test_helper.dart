// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
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
}) => test(
  description,
  () async {
    final dartDir = await _setup();
    for (final entry in files.entries) {
      final fileMode =
          entry.key == 'pubspec.yaml' ? FileMode.append : FileMode.write;

      final file = File.fromUri(dartDir.uri.resolve(entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value, mode: fileMode);
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
  timeout: timeout ?? const Timeout(Duration(minutes: 2)),
  skip: skip,
  tags: tags,
  onPlatform: onPlatform,
  retry: retry,
);

Matcher emitsNoIssues() =>
    emitsInOrder(<dynamic>['Analyzing...', '', 'No issues found!', emitsDone]);

Matcher customLint(String lint, String location) {
  final realLocation = location.replaceAll('/', path.separator);
  return matches(
    RegExp(
      '^\\s*${RegExp.escape(realLocation)} • .* • ${RegExp.escape(lint)} • INFO\\s*\$',
    ),
  );
}

Matcher emitsCustomLint(String lint, List<String> locations) =>
    emitsCustomLints({lint: locations});

Matcher emitsCustomLints(Map<String, List<String>> lints) {
  final issuesCount = lints.values.fold(0, (p, l) => p + l.length);
  return emitsInAnyOrder(<dynamic>[
    'Analyzing...',
    '',
    ...lints.entries.expand<Matcher>(
      (e) => e.value.map((location) => customLint(e.key, location)),
    ),
    '',
    if (issuesCount == 1) '1 issue found.' else '$issuesCount issues found.',
    emitsDone,
  ]);
}

Future<Directory> _setup() async {
  final testDir = await Directory.systemTemp.createTemp();
  printOnFailure('Using temporary directory: $testDir');
  await _runDart(const [
    'create',
    '--template',
    'package-simple',
    'dart_test_tools_integration_test',
  ], testDir);

  final dartDir = Directory.fromUri(
    testDir.uri.resolve('dart_test_tools_integration_test'),
  );

  final dartTestToolsConfig = {'path': Directory.current.path};
  await _runDart([
    'pub',
    'add',
    'meta',
    'dev:custom_lint',
    'dev:dart_test_tools:${json.encode(dartTestToolsConfig)}',
  ], dartDir);

  final analysisOptionsFile = File.fromUri(
    dartDir.uri.resolve('analysis_options.yaml'),
  );
  await analysisOptionsFile.writeAsString(mode: FileMode.append, '''
analyzer:
  plugins:
    - custom_lint
''');

  await Directory.fromUri(dartDir.uri.resolve('lib')).delete(recursive: true);
  await Directory.fromUri(dartDir.uri.resolve('test')).delete(recursive: true);
  await Directory.fromUri(
    dartDir.uri.resolve('example'),
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
