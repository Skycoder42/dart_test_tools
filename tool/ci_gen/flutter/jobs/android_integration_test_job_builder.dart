import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/secrets.dart';
import '../../common/steps/validate_inputs_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../flutter_platform.dart';
import '../steps/android_integration_test_builder.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class AndroidIntegrationTestJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  final JobIdOutput enabledPlatformsOutput;
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;
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

  AndroidIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
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
  });

  @override
  JobId get id => const JobId('integration_tests_android');

  @override
  Job build() => Job(
        name: 'Integration tests (android)',
        ifExpression: integrationTestPaths.ne(Expression.empty) &
            EnabledPlatforms.check(
              enabledPlatformsOutput.expression,
              Expression.literal(FlutterPlatform.android.platform),
            ),
        needs: {
          enabledPlatformsOutput.jobId,
        },
        runsOn: FlutterPlatform.android.os.id,
        steps: [
          ...ValidateInputsBuilder({
            WorkflowInputs.firebaseProjectId.name: firebaseProjectId,
            WorkflowSecrets.firebaseCredentials.name: firebaseCredentials,
          }).build(),
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.android.platform),
          ),
          ...AndroidIntegrationTestBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestProject: integrationTestProject,
            integrationTestCacheConfig: integrationTestCacheConfig,
            firebaseProjectId: firebaseProjectId,
            firebaseCredentials: firebaseCredentials,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
