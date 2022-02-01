// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:dart_test_tools/src/common/file_result.dart';
import 'package:dart_test_tools/src/common/linter.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

typedef LinterFactor<TLinter extends Linter> = TLinter Function(Logger? logger);

typedef LinterExpectFn = FutureOr<void> Function(Stream<FileResult> result);

typedef LoggerExpectFn = FutureOr<void> Function(Stream<LogRecord> onRecord);

T _any<T>() => (null as dynamic) as T;

TypeMatcher<T> _isAFileResult<T extends FileResult>(T Function() f) => isA<T>();

TypeMatcher<ResultLocation> isResultLocation() => isA<ResultLocation>();

extension ResultLocationTypeMatcherX on TypeMatcher<ResultLocation> {
  TypeMatcher<ResultLocation> havingRelPath(String path) => having(
        (l) => l.relPath,
        'relPath',
        pathEquals(path),
      );
}

Matcher isAccepted([dynamic resultLocationMatcher = anything]) =>
    _isAFileResult(
      () => $FileResult.accepted(
        resultLocation: _any(),
      ),
    ).having(
      (r) => r.resultLocation,
      'resultLocation',
      resultLocationMatcher,
    );

Matcher isSkipped({
  dynamic reasonMatcher = anything,
  dynamic resultLocationMatcher = anything,
}) =>
    _isAFileResult(
      () => $FileResult.skipped(
        reason: _any(),
        resultLocation: _any(),
      ),
    )
        .having(
          (r) => r.reason,
          'reason',
          reasonMatcher,
        )
        .having(
          (r) => r.resultLocation,
          'resultLocation',
          resultLocationMatcher,
        );

Matcher isRejected({
  dynamic reasonMatcher = anything,
  dynamic resultLocationMatcher = anything,
}) =>
    _isAFileResult(
      () => $FileResult.rejected(
        resultLocation: _any(),
        reason: _any(),
      ),
    )
        .having(
          (r) => r.reason,
          'reason',
          reasonMatcher,
        )
        .having(
          (r) => r.resultLocation,
          'resultLocation',
          resultLocationMatcher,
        );

Matcher isFailure({
  dynamic errorMatcher = anything,
  dynamic stackTraceMatcher = anything,
  dynamic resultLocationMatcher = anything,
}) =>
    _isAFileResult(
      () => $FileResult.failure(
        resultLocation: _any(),
        error: _any(),
      ),
    )
        .having(
          (r) => r.error,
          'error',
          errorMatcher,
        )
        .having(
          (r) => r.stackTrace,
          'stackTrace',
          stackTraceMatcher,
        )
        .having(
          (r) => r.resultLocation,
          'resultLocation',
          resultLocationMatcher,
        );

Matcher pathEquals(String expected) => predicate<String>(
      (actual) => path.equals(actual, expected),
      'is same path as $expected',
    );

@isTest
void analysisTest<TLinter extends Linter>(
  String description, {
  Map<String, String> files = const {},
  required LinterFactor<TLinter> createLinter,
  required Matcher expectResults,
  Matcher? expectLog,
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

        final Logger logger;
        if (expectLog != null) {
          logger = Logger.detached('test')..level = Level.ALL;
          expect(logger.onRecord, expectLog);
        } else {
          logger = Logger('test');
        }

        final linter = createLinter(logger)
          ..contextCollection = AnalysisContextCollection(
            includedPaths: [dartDir.path],
          );
        await expectLater(linter.call(), expectResults);

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

  await _runDart(const ['pub', 'add', 'meta'], dartDir);

  await File.fromUri(
    dartDir.uri.resolve('lib/src/dart_test_tools_integration_test_base.dart'),
  ).delete();
  await File.fromUri(
    dartDir.uri.resolve('lib/dart_test_tools_integration_test.dart'),
  ).delete();

  return dartDir;
}

Future<void> _cleanup(Directory dartDir) async {
  await dartDir.parent.delete(recursive: true);
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
