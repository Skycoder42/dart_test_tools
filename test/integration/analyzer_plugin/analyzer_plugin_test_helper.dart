import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

typedef TypeMatcherCb<T> = TypeMatcher<T> Function(TypeMatcher<T> match);

typedef AnalysisLine = ({
  String level,
  String type,
  String name,
  String path,
  int line,
  int column,
  int length,
  String message,
});

@isTest
void analyzerPluginTest(
  String description, {
  required LintCode code,
  Map<String, String> files = const {},
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
      final fileMode = entry.key == 'pubspec.yaml'
          ? FileMode.append
          : FileMode.write;

      final file = File.fromUri(dartDir.uri.resolve(entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value, mode: fileMode);
    }

    await _expectDart(
      const ['analyze', '--fatal-infos', '--format', 'machine'],
      codeName: code.name.toUpperCase(),
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

Matcher emitsNoIssues() => emitsInOrder(<dynamic>[emitsDone]);

Matcher _isLint(String location, int line, int column) {
  final realLocation = location.replaceAll('/', path.separator);
  return isA<AnalysisLine>()
      .having((m) => m.type, 'type', 'STATIC_WARNING')
      .having((m) => m.level, 'level', 'INFO')
      .having((m) => m.path, 'path', endsWith(realLocation))
      .having((m) => m.line, 'line', line)
      .having((m) => m.column, 'column', column);
}

Matcher emitsLints(List<(String, int, int)> locations) =>
    emitsInAnyOrder(<dynamic>[
      for (final location in locations)
        _isLint(location.$1, location.$2, location.$3),
      emitsDone,
    ]);

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
    'dev:dart_test_tools:${json.encode(dartTestToolsConfig)}',
  ], dartDir);

  final analysisOptionsFile = File.fromUri(
    dartDir.uri.resolve('analysis_options.yaml'),
  );
  await analysisOptionsFile.writeAsString(mode: FileMode.append, '''
plugins:
  dart_test_tools:
    path: ${Directory.current.path}
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
  required String codeName,
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
    dartProc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => line.split('|'))
        .map<AnalysisLine>(
          (line) => (
            level: line[0],
            type: line[1],
            name: line[2],
            path: line[3],
            line: int.parse(line[4]),
            column: int.parse(line[5]),
            length: int.parse(line[6]),
            message: line[7],
          ),
        )
        .where((r) => r.name == codeName),
    expectedOutput,
  );
  await expectLater(dartProc.exitCode, completes);
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
