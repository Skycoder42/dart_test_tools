@TestOn('dart-vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/src/hooks/hook_scripts.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'git_test_repo.dart';

// Stands in for `dart`: each check prints its output, leaves marks and can
// sleep or wait for a mark of the other check before it finishes.
const _dartStub = r'''
#!/bin/sh
case "$1" in
  analyze)
    name=analyze
    wait_for=${ANALYZE_WAIT_FOR:-}
    delay=${ANALYZE_DELAY:-0}
    code=${ANALYZE_EXIT:-0}
    ;;
  run)
    name=flutter-compat
    wait_for=${FLUTTER_COMPAT_WAIT_FOR:-}
    delay=${FLUTTER_COMPAT_DELAY:-0}
    code=${FLUTTER_COMPAT_EXIT:-0}
    ;;
  *)
    echo "unexpected dart call: $*" >&2
    exit 4
    ;;
esac
echo "$*" >"$MARKS/$name.args"
cat >"$MARKS/$name.stdin"
touch "$MARKS/$name.started"
echo "$name output"
sleep "$delay"
if [ -n "$wait_for" ]; then
  tries=0
  while [ ! -e "$MARKS/$wait_for" ]; do
    tries=$((tries + 1))
    if [ "$tries" -ge 100 ]; then
      echo "$name timed out waiting for $wait_for"
      exit 3
    fi
    sleep 0.1
  done
fi
touch "$MARKS/$name.done"
exit "$code"
''';

void main() {
  group('pre-push', () {
    late GitTestRepo repo;
    late Directory marks;
    late Directory stubBin;

    File mark(String name) => File(join(marks.path, name));

    Map<String, String> hookEnv([Map<String, String> extra = const {}]) => {
      ...repo.env,
      ...prependPath(stubBin.path),
      'MARKS': marks.path,
      ...extra,
    };

    Future<File> installHook({required bool flutterCompat}) async {
      final hook = repo.file(join('.git', 'hooks', 'pre-push'));
      await writeExecutable(
        hook,
        HookScripts.prePush(flutterCompat: flutterCompat),
      );
      return hook;
    }

    Future<ProcessResult> runHook({
      bool flutterCompat = true,
      Map<String, String> env = const {},
    }) async {
      final hook = await installHook(flutterCompat: flutterCompat);
      return await Process.run(
        shellExecutable,
        [hook.path],
        workingDirectory: repo.dir.path,
        environment: hookEnv(env),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    }

    setUp(() async {
      repo = await GitTestRepo.create();
      marks = Directory(join(repo.root.path, 'marks'));
      await marks.create();
      stubBin = Directory(join(repo.root.path, 'bin'));
      await writeExecutable(File(join(stubBin.path, 'dart')), _dartStub);
    });

    tearDown(() => repo.dispose());

    test('both checks pass', () async {
      final result = await runHook();

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains('analyze: passed'));
      expect(result.stdout, contains('flutter-compat: passed'));
      expect(result.stdout, isNot(contains('output')));
      expect(result.stdout, isNot(contains('checks completed')));
      expect(
        mark('analyze.args').readAsStringSync().trim(),
        ['analyze', '--fatal-infos'].join(' '),
      );
      expect(
        mark('flutter-compat.args').readAsStringSync().trim(),
        ['run', 'dart_test_tools:flutter_compat'].join(' '),
      );
    });

    test('fails if analyze fails', () async {
      final result = await runHook(env: {'ANALYZE_EXIT': '1'});

      expect(result.exitCode, 1);
      expect(result.stdout, contains('analyze: failed'));
      expect(result.stdout, contains('analyze output'));
      expect(result.stdout, contains('flutter-compat: passed'));
      expect(result.stdout, isNot(contains('flutter-compat output')));
    });

    test('fails if flutter-compat fails', () async {
      final result = await runHook(env: {'FLUTTER_COMPAT_EXIT': '1'});

      expect(result.exitCode, 1);
      expect(result.stdout, contains('analyze: passed'));
      expect(result.stdout, isNot(contains('analyze output')));
      expect(result.stdout, contains('flutter-compat: failed'));
      expect(result.stdout, contains('flutter-compat output'));
    });

    test('runs the checks in parallel', () async {
      final result = await runHook(
        env: {'ANALYZE_WAIT_FOR': 'flutter-compat.started'},
      );

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    });

    test('prints the results in the order the checks finish', () async {
      final result = await runHook(
        env: {
          // the delay keeps both checks from being reported in the same round
          'ANALYZE_DELAY': '0.5',
          'ANALYZE_EXIT': '1',
          'FLUTTER_COMPAT_EXIT': '1',
        },
      );

      expect(result.exitCode, 1, reason: '${result.stdout}${result.stderr}');
      final stdout = result.stdout as String;
      final flutterCompatHeader = stdout.indexOf('flutter-compat: failed');
      final flutterCompatOutput = stdout.indexOf('flutter-compat output');
      final analyzeHeader = stdout.indexOf('analyze: failed');
      final analyzeOutput = stdout.indexOf('analyze output');
      expect(flutterCompatHeader, isNot(-1));
      expect(flutterCompatOutput, greaterThan(flutterCompatHeader));
      expect(analyzeHeader, greaterThan(flutterCompatOutput));
      expect(analyzeOutput, greaterThan(analyzeHeader));
    });

    test('shows a progress indicator on terminals', () async {
      final hook = await installHook(flutterCompat: true);
      // script runs the hook with a pseudo terminal as stdout
      final result = await Process.run(
        'script',
        ['--quiet', '--return', '--command', 'sh ${hook.path}', '/dev/null'],
        workingDirectory: repo.dir.path,
        environment: hookEnv({
          'ANALYZE_DELAY': '0.5',
          'FLUTTER_COMPAT_DELAY': '1',
        }),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final stdout = result.stdout as String;
      expect(result.exitCode, 0, reason: '$stdout${result.stderr}');
      expect(stdout, contains('[0/2] checks completed'));
      expect(stdout, contains('[1/2] checks completed'));
      expect(stdout, isNot(contains('[2/2]')));
      expect(
        stdout.indexOf('[1/2] checks completed'),
        greaterThan(stdout.indexOf('analyze: passed')),
      );
      // the indicator is cleared before the last result
      expect(stdout.trimRight(), endsWith('flutter-compat: passed'));
    }, testOn: 'linux');

    test('skips flutter-compat if disabled', () async {
      final result = await runHook(flutterCompat: false);

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains('analyze: passed'));
      expect(result.stdout, isNot(contains('flutter-compat')));
      expect(mark('flutter-compat.started').existsSync(), isFalse);
    });

    group('git push', () {
      late Directory remote;

      Future<ProcessResult> push(Map<String, String> env) => Process.run(
        'git',
        ['push', 'origin', 'main'],
        workingDirectory: repo.dir.path,
        environment: hookEnv(env),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      Future<bool> remoteHasMain() async {
        final result = await repo.git(
          ['rev-parse', '--verify', '--quiet', 'refs/heads/main'],
          check: false,
          workingDirectory: remote.path,
        );
        return result.exitCode == 0;
      }

      setUp(() async {
        remote = Directory(join(repo.root.path, 'remote.git'));
        await repo.git(['init', '--bare', '-b', 'main', remote.path]);
        await repo.git(['remote', 'add', 'origin', remote.path]);
        await repo.writeFile('README.md', '# readme\n');
        await repo.git(['add', '.']);
        await repo.git(['commit', '-m', 'x']);
        await installHook(flutterCompat: true);
      });

      test('runs the hook and ignores the pushed refs on stdin', () async {
        final result = await push(const {});

        expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
        final output = '${result.stdout}${result.stderr}';
        expect(output, contains('analyze: passed'));
        expect(output, contains('flutter-compat: passed'));
        expect(mark('analyze.stdin').readAsStringSync(), isEmpty);
        expect(mark('flutter-compat.stdin').readAsStringSync(), isEmpty);
        expect(await remoteHasMain(), isTrue);
      });

      test('aborts the push if a check fails', () async {
        final result = await push({'FLUTTER_COMPAT_EXIT': '1'});

        expect(result.exitCode, isNot(0));
        expect(
          '${result.stdout}${result.stderr}',
          contains('flutter-compat: failed'),
        );
        expect(await remoteHasMain(), isFalse);
      });
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
