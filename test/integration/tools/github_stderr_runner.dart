import 'package:dart_test_tools/src/tools/github.dart';

// Helper script for github_test.dart: runs a failing process with
// logToStderr enabled, so the test can verify that nothing is written to
// stdout.
Future<void> main() => Github.runZoned(
  logToStderr: true,
  () => Github.exec('bash', const [
    '-c',
    'echo child-stdout; echo child-stderr >&2; exit 3',
  ]),
);
