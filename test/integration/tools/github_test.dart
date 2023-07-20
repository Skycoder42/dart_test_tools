@TestOn('dart-vm')
library github_test;

import 'dart:io';

import 'package:dart_test_tools/src/test/test_data.dart';
import 'package:dart_test_tools/src/tools/github.dart';
import 'package:test/test.dart';

void main() {
  group('$Github', () {
    testData<(Directory Function(), String)>('env is reported correctly', [
      (() => Github.env.githubWorkspace, 'GITHUB_WORKSPACE'),
      (() => Github.env.runnerTemp, 'RUNNER_TEMP'),
    ], (fixture) {
      expect(
        fixture.$1().path,
        Platform.environment[fixture.$2],
      );
    });

    group('log', () {
      testData<(void Function(String), String)>(
        'Logs correct message kind',
        [
          (Github.logDebug, '::debug::test\n'),
          (Github.logInfo, 'Info: test\n'),
          (Github.logNotice, '::notice::test\n'),
          (Github.logWarning, '::warning::test\n'),
          (Github.logError, '::error::test\n'),
        ],
        (fixture) {
          expect(() => fixture.$1('test'), prints(fixture.$2));
        },
      );

      test('logGroup logs message in group', () {
        expect(
          () => Github.logGroup('test-title', () => print('test-message')),
          prints(
            '::group::test-title\n'
            'test-message\n'
            '::endgroup::\n',
          ),
        );
      });

      test('logGroupAsync logs async message in group', () {
        expect(
          () => Github.logGroupAsync(
            'test-title',
            () => Future.delayed(
              Duration(seconds: 1),
              () => print('test-message'),
            ),
          ),
          prints(
            '::group::test-title\n'
            'test-message\n'
            '::endgroup::\n',
          ),
        );
      });

      test('runZoned logs captured errors', () {
        final exception = Exception('Test-Failure');
        expect(
          () => Github.runZoned(() => throw exception),
          prints(
            allOf(
              startsWith(
                '::error::$exception\n'
                '::group::Stack-Trace\n',
              ),
              endsWith('::endgroup::\n'),
            ),
          ),
        );
      });
    });

    group('exec', testOn: 'posix', () {
      test('invokes process', () {
        expect(
          () => Github.exec('bash', const ['-c', 'true']),
          allOf(
            prints('[command] bash -c true\n'),
            returnsNormally,
          ),
        );
      });

      test('throws on failure', () {
        expect(
          Github.exec('bash', const ['-c', 'exit 42']),
          throwsA(isException.having(
            (m) => m.toString(),
            'toString()',
            contains('42'),
          )),
        );
      });

      test('completes with exit code', () {
        expect(
          Github.exec('bash', const ['-c', 'exit 42'], expectedExitCode: null),
          completion(42),
        );
      });

      test('uses custom env vars', () {
        expect(
          Github.exec(
            'bash',
            const ['-c', r'exit $TEST_RESULT'],
            environment: const {'TEST_RESULT': '24'},
            expectedExitCode: null,
          ),
          completion(24),
        );
      });

      test('uses custom working dir', () {
        final tmpDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tmpDir.delete(recursive: true));
        File.fromUri(tmpDir.uri.resolve('test-file')).writeAsStringSync('17');

        expect(
          Github.exec(
            'bash',
            const ['-c', r'exit $(cat test-file)'],
            workingDirectory: tmpDir,
            expectedExitCode: null,
          ),
          completion(17),
        );
      });
    });

    group('execLines', testOn: 'posix', () {
      test('invokes process', () {
        expect(
          () => Github.execLines('bash', const ['-c', 'true']).drain(),
          allOf(
            prints('[command] bash -c true\n'),
            returnsNormally,
          ),
        );
      });

      test('throws on failure', () {
        expect(
          Github.execLines('bash', const ['-c', 'exit 42']),
          emitsInOrder([
            emitsError(isException.having(
              (m) => m.toString(),
              'toString()',
              contains('42'),
            )),
            emitsDone,
          ]),
        );
      });

      test('completes with exit code', () {
        expect(
          Github.execLines(
            'bash',
            const ['-c', 'exit 42'],
            expectedExitCode: null,
          ),
          emitsDone,
        );
      });

      test('streams output lines', () {
        expect(
          Github.execLines(
            'bash',
            const [
              '-c',
              'echo "Hello world"; echo ""; echo -n test; echo test'
            ],
            expectedExitCode: null,
          ),
          emitsInOrder([
            'Hello world',
            '',
            'testtest',
            emitsDone,
          ]),
        );
      });

      test('uses custom env vars', () {
        expect(
          Github.execLines(
            'bash',
            const ['-c', r'echo $TEST_RESULT'],
            environment: const {'TEST_RESULT': 'test-result'},
          ),
          emits('test-result'),
        );
      });

      test('uses custom working dir', () {
        final tmpDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tmpDir.delete(recursive: true));

        expect(
          Github.execLines(
            'bash',
            const ['-c', r'echo $PWD'],
            workingDirectory: tmpDir,
          ),
          emits(tmpDir.resolveSymbolicLinksSync()),
        );
      });
    });
  });
}
