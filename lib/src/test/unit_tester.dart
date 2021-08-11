import 'dart:io';

import '../common/runner.dart';
import 'cli.dart';
import 'config.dart';
import 'excludes.dart';
import 'mode.dart';
import 'target.dart';

class UnitTester {
  final Cli cli;
  final TestConfig config;
  final ExcludeConfig excludes;
  final Runner runner;

  UnitTester({
    required this.cli,
    required this.config,
    required this.excludes,
    required this.runner,
  });

  Future<bool> get shouldRun async {
    if (!cli.modes.contains(Mode.unit)) {
      return false;
    }

    return Stream.fromIterable(config.unit.paths)
        .asyncMap((path) => Directory(path).exists())
        .every((exists) => exists);
  }

  Future<void> run() async {
    if (cli.coverage) {
      await _prepareCoverage();
    }

    if (cli.platforms.contains(Target.vm)) {
      await _runVmTests();
    }

    if (cli.platforms.contains(Target.js)) {
      await _runJsTests();
    }

    if (cli.coverage) {
      await _formatCoverage();
    }

    if (cli.htmlCoverage) {
      await _generateHtmlCoverage();
    }

    if (cli.openCoverage) {
      await _openCoverage();
    }
  }

  Future<void> _prepareCoverage() async {
    final coverageDir = Directory('coverage');
    if (await coverageDir.exists()) {
      await Directory('coverage').delete(recursive: true);
    }
  }

  Future<void> _runVmTests() async {
    await runner.dart([
      'test',
      if (cli.coverage) '--coverage=coverage',
      ...config.unit.paths,
    ]);
  }

  Future<void> _runJsTests() async {
    await runner.dart([
      'test',
      '-p',
      'chrome',
      if (cli.coverage) '--coverage=coverage',
      ...config.unit.paths,
    ]);
  }

  Future<void> _formatCoverage() async {
    await runner.dart(const [
      'run',
      'coverage:format_coverage',
      '--lcov',
      '--check-ignore',
      '--in=coverage',
      '--out=coverage/lcov.info',
      '--packages=.packages',
      '--report-on=lib',
    ]);
  }

  Future<void> _generateHtmlCoverage() async {
    if (excludes.patterns.isNotEmpty) {
      await runner(
        'lcov',
        [
          '--remove',
          'coverage/lcov.info',
          '--output-file',
          'coverage/lcov_cleaned.info',
          ...excludes.patterns,
        ],
      );
    }

    await runner(
      'genhtml',
      [
        '--no-function-coverage',
        '-o',
        'coverage/html',
        if (excludes.patterns.isEmpty)
          'coverage/lcov.info'
        else
          'coverage/lcov_cleaned.info',
      ],
    );
  }

  Future<void> _openCoverage() async {
    final String executable;
    if (Platform.isLinux) {
      executable = 'xdg-open';
    } else if (Platform.isWindows) {
      executable = 'start';
    } else if (Platform.isMacOS) {
      executable = 'open';
    } else {
      throw UnsupportedError(
        '${Platform.operatingSystem} is not supported',
      );
    }

    await runner(executable, const ['coverage/html/index.html']);
  }
}
