@TestOn('dart-vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('flutter_compat', () {
    final script = absolute('bin', 'flutter_compat.dart');
    late Directory testDir;

    Future<void> writePackage(String dependencies) async {
      final file = File(join(testDir.path, 'pubspec.yaml'));
      await file.writeAsString('''
name: test_package
version: 1.0.0
environment:
  sdk: ^3.9.0
dependencies:
$dependencies''');
    }

    Future<ProcessResult> flutterCompat(
      List<String> args, {
      String? workingDirectory,
    }) => Process.run(
      Platform.resolvedExecutable,
      ['run', script, ...args],
      workingDirectory: workingDirectory ?? testDir.path,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
    });

    tearDown(() => testDir.delete(recursive: true));

    test('exits with 0 for a compatible package', () async {
      await writePackage('  path: ^1.9.0\n');

      final result = await flutterCompat(const []);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    });

    test('exits with 1 for an incompatible package', () async {
      await writePackage('  meta: ">=1.15.0 <1.17.0"\n');

      final result = await flutterCompat(const []);

      expect(result.exitCode, 1, reason: '${result.stdout}${result.stderr}');
      expect('${result.stdout}${result.stderr}', contains('test_package'));
    });

    test('checks the directory given with -d', () async {
      await writePackage('  meta: ">=1.15.0 <1.17.0"\n');

      final result = await flutterCompat([
        '-d',
        testDir.path,
      ], workingDirectory: Directory.systemTemp.path);

      expect(result.exitCode, 1, reason: '${result.stdout}${result.stderr}');
      expect('${result.stdout}${result.stderr}', contains('test_package'));
    });

    test('exits with 2 without pubspec.yaml', () async {
      final result = await flutterCompat(const []);

      expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
      expect(result.stderr, contains('pubspec.yaml'));
    });

    test('prints the usage with --help', () async {
      final result = await flutterCompat(['--help']);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains('--directory'));
    });

    test('exits with 2 and the usage on unknown options', () async {
      final result = await flutterCompat(['--unknown']);

      expect(result.exitCode, 2, reason: '${result.stdout}${result.stderr}');
      expect(result.stderr, allOf(contains('Usage:'), contains('--directory')));
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
