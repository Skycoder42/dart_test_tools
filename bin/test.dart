import 'dart:io';

import 'package:dart_test_tools/src/common/runner.dart';
import 'package:dart_test_tools/src/test/cli.dart';
import 'package:dart_test_tools/src/test/integration_tester.dart';
import 'package:dart_test_tools/src/test/unit_tester.dart';

Future<void> main(List<String> arguments) async {
  final runner = Runner();
  final cli = Cli.parse(arguments);

  if (cli == null) {
    return;
  }

  try {
    final unitTester = UnitTester(cli: cli, runner: runner);
    if (await unitTester.shouldRun) {
      await unitTester.run();
    }

    final integrationTester = IntegrationTester(cli: cli, runner: runner);
    if (await integrationTester.shouldRun) {
      await integrationTester.run();
    }
  } on ChildErrorException catch (e) {
    exitCode = e.exitCode;
  }
}
