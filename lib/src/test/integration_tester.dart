import 'dart:io';

import '../common/runner.dart';
import 'cli.dart';
import 'config.dart';
import 'mode.dart';
import 'target.dart';

class IntegrationTester {
  final Cli cli;
  final TestConfig config;
  final Runner runner;

  IntegrationTester({
    required this.cli,
    required this.config,
    required this.runner,
  });

  Future<bool> get shouldRun async {
    if (!cli.modes.contains(Mode.integration)) {
      return false;
    }

    return Stream.fromIterable(config.integration.paths)
        .asyncMap((path) => Directory(path).exists())
        .every((exists) => exists);
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
    await runner.dart([
      'test',
      ...config.integration.paths,
    ]);
  }

  Future<void> _runJs() async {
    await runner.dart([
      'test',
      '-p',
      'chrome',
      ...config.integration.paths,
    ]);
  }
}
