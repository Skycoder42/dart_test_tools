import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'prepare_integration_test_builder.dart';

class WebIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestProject;
  final Expression integrationTestCacheConfig;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const WebIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...PrepareIntegrationTestBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          removePubspecOverrides: removePubspecOverrides,
          integrationTestSetup: integrationTestSetup,
          integrationTestProject: integrationTestProject,
          integrationTestCacheConfig: integrationTestCacheConfig,
          platform: ExpressionOrValue.value(FlutterPlatform.web.platform),
          baseTool: baseTool,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Run integration tests',
          run: r'$ChromeWebDriver/chromedriver --port=4444 & '
              '$baseTool drive '
              '--driver test_driver/integration_test.dart '
              "--target '$integrationTestPaths' "
              '--release '
              '-d chrome --browser-name chrome '
              r'|| [ $? = 79 ]',
          workingDirectory: '$workingDirectory/$integrationTestProject',
          shell: 'bash',
        ),
      ];
}
