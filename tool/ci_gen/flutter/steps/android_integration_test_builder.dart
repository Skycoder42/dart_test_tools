import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'prepare_integration_test_builder.dart';
import 'setup_gcloud_builder.dart';

base mixin AndroidIntegrationTestConfig
    on JobConfig, PrepareIntegrationTestConfig, SetupGCloudConfig {
  late Expression integrationTestPaths;
}

class AndroidIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final AndroidIntegrationTestConfig config;

  const AndroidIntegrationTestBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        ...PrepareIntegrationTestBuilder(
          config: config,
          platform: ExpressionOrValue.value(FlutterPlatform.android.platform),
        ).build(),
        Step.run(
          name: 'Build integration test app',
          run: '${config.baseTool} build apk --debug '
              "--target '${config.integrationTestPaths}'",
          workingDirectory: config.integrationTestWorkingDirectory,
        ),
        Step.run(
          name: 'Build test instrumentation app',
          run: './gradlew app:assembleAndroidTest',
          workingDirectory: '${config.integrationTestWorkingDirectory}/android',
        ),
        ...SetupGCloudBuilder(config: config).build(),
        Step.run(
          name: 'Run integration tests',
          run: 'gcloud firebase test android run '
              '--type instrumentation '
              '--app build/app/outputs/apk/debug/app-debug.apk '
              '--test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk',
          workingDirectory: config.integrationTestWorkingDirectory,
        ),
      ];
}
