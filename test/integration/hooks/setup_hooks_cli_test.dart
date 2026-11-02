@TestOn('dart-vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/src/hooks/hook_scripts.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'git_test_repo.dart';

void main() {
  group('setup_hooks', () {
    final script = absolute('bin', 'setup_hooks.dart');
    late GitTestRepo repo;

    File hook(String name) => repo.file(join('.git', 'hooks', name));

    Future<ProcessResult> setupHooks([List<String> args = const []]) =>
        Process.run(
          Platform.resolvedExecutable,
          ['run', script, ...args],
          workingDirectory: repo.dir.path,
          environment: repo.env,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );

    setUp(() async {
      repo = await GitTestRepo.create();
    });

    tearDown(() => repo.dispose());

    test('installs both hooks and prints their paths', () async {
      final result = await setupHooks();

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(hook('pre-commit').readAsStringSync(), HookScripts.preCommit);
      expect(
        hook('pre-push').readAsStringSync(),
        HookScripts.prePush(flutterCompat: true),
      );
      expect(
        result.stdout,
        allOf(
          contains('Installed '),
          contains(join('.git', 'hooks', 'pre-commit')),
          contains(join('.git', 'hooks', 'pre-push')),
        ),
      );
    });

    test('prints warnings', () async {
      final result = await setupHooks();

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(
        result.stderr,
        allOf(contains('Warning: '), contains('dart_test_tools')),
      );
    });

    test('leaves out the flutter compat check if disabled', () async {
      final result = await setupHooks(['--no-flutter-compat']);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(
        hook('pre-push').readAsStringSync(),
        HookScripts.prePush(flutterCompat: false),
      );
      expect(result.stderr, isNot(contains('Warning: ')));
    });

    test('refuses to replace foreign hooks without --force', () async {
      const foreign = '#!/bin/sh\nexit 0\n';
      await repo.writeFile('.git/hooks/pre-commit', foreign);

      final result = await setupHooks();

      expect(result.exitCode, 1);
      expect(result.stderr, allOf(contains('pre-commit'), contains('--force')));
      expect(hook('pre-commit').readAsStringSync(), foreign);
      expect(hook('pre-push').existsSync(), isFalse);
    });

    test('replaces foreign hooks with --force', () async {
      await repo.writeFile('.git/hooks/pre-commit', '#!/bin/sh\nexit 0\n');

      final result = await setupHooks(['--force']);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(hook('pre-commit').readAsStringSync(), HookScripts.preCommit);
    });

    test('prints the usage with --help', () async {
      final result = await setupHooks(['--help']);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains('--[no-]flutter-compat'));
      expect(hook('pre-commit').existsSync(), isFalse);
    });

    test('fails with the usage on unknown options', () async {
      final result = await setupHooks(['--unknown']);

      expect(result.exitCode, 1);
      expect(result.stderr, allOf(contains('Usage:'), contains('--force')));
      expect(hook('pre-commit').existsSync(), isFalse);
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
