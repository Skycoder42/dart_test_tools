import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'prepare_integration_test_builder.dart';

base mixin WebIntegrationTestConfig on JobConfig, PrepareIntegrationTestConfig {
  late Expression integrationTestPaths;
}

class WebIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final WebIntegrationTestConfig config;

  const WebIntegrationTestBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        ...PrepareIntegrationTestBuilder(
          config: config,
          platform: ExpressionOrValue.value(FlutterPlatform.web.platform),
        ).build(),
        Step.run(
          name: 'Run integration tests',
          run: r'$ChromeWebDriver/chromedriver --port=4444 & '
              '${config.baseTool} drive '
              '--driver test_driver/integration_test.dart '
              "--target '${config.integrationTestPaths}' "
              '--release '
              '-d chrome --browser-name chrome '
              r'|| [ $? = 79 ]',
          workingDirectory: config.integrationTestWorkingDirectory,
          shell: 'bash',
        ),
      ];
}
