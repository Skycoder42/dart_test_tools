import 'dart:io';

import '../common/runner.dart';
import 'cli.dart';
import 'mode.dart';
import 'target.dart';

class IntegrationTester {
  static const integrationTestDir = 'test/integration';

  final Cli cli;
  final Runner runner;

  IntegrationTester({
    required this.cli,
    required this.runner,
  });

  Future<bool> get shouldRun async {
    if (!cli.modes.contains(Mode.integration)) {
      return false;
    }

    return Directory(integrationTestDir).exists();
  }

  Future<void> run() async {
    if (cli.platforms.contains(Target.vm)) {
      await _runVm();
    }

    if (cli.platforms.contains(Target.js)) {
      await _runJs();
    }
  }

  Future<void> _runVm() async {
    await runner.dart(const [
      'test',
      integrationTestDir,
    ]);
  }

  Future<void> _runJs() async {
    await runner.dart(const [
      'test',
      '-p',
      'chrome',
      integrationTestDir,
    ]);
  }
}
