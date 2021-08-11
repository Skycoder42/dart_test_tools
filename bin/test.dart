import 'dart:io';

import 'package:dart_test_tools/src/common/config.dart';
import 'package:dart_test_tools/src/common/runner.dart';
import 'package:dart_test_tools/src/test/cli.dart';
import 'package:dart_test_tools/src/test/config.dart';
import 'package:dart_test_tools/src/test/excludes.dart';
import 'package:dart_test_tools/src/test/integration_tester.dart';
import 'package:dart_test_tools/src/test/unit_tester.dart';

Future<void> main(List<String> arguments) async {
  final runner = Runner();
  final cli = Cli.parse(arguments);

  if (cli == null) {
    return;
  }

  try {
    final testConfig = TestConfig.fromYaml(
      await DartTestToolsConfig.readYamlFor(cli.configPath, TestConfig.key),
    );
    final excludeConfig = ExcludeConfig.fromAnalysisOptionsYaml(
      await DartTestToolsConfig.readYaml(cli.analysisOptionsPath),
    );

    final unitTester = UnitTester(
      cli: cli,
      config: testConfig,
      excludes: excludeConfig,
      runner: runner,
    );
    if (await unitTester.shouldRun) {
      await unitTester.run();
    }

    final integrationTester = IntegrationTester(
      cli: cli,
      config: testConfig,
      runner: runner,
    );
    if (await integrationTester.shouldRun) {
      await integrationTester.run();
    }
  } on ChildErrorException catch (e) {
    exitCode = e.exitCode;
  }
}
