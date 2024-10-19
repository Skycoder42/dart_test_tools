import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'prepare_integration_test_builder.dart';
import 'setup_gcloud_builder.dart';

class AndroidIntegrationTestBuilder implements StepBuilder {
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
  final Expression firebaseProjectId;
  final Expression firebaseCredentials;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const AndroidIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
    required this.firebaseProjectId,
    required this.firebaseCredentials,
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
          platform: ExpressionOrValue.value(FlutterPlatform.android.platform),
          baseTool: baseTool,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Build integration test app',
          run: "$baseTool build apk --debug --target '$integrationTestPaths'",
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
        Step.run(
          name: 'Build test instrumentation app',
          run: './gradlew app:assembleAndroidTest',
          workingDirectory: '$workingDirectory/$integrationTestProject/android',
        ),
        ...SetupGCloudBuilder(
          firebaseProjectId: firebaseProjectId,
          firebaseCredentials: firebaseCredentials,
        ).build(),
        Step.run(
          name: 'Run integration tests',
          run: 'gcloud firebase test android run '
              '--type instrumentation '
              '--app build/app/outputs/apk/debug/app-debug.apk '
              '--test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk',
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
      ];
}
