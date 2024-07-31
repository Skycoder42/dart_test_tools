import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../flutter_platform.dart';
import '../steps/web_integration_test_builder.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class WebIntegrationTestJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  final JobIdOutput enabledPlatformsOutput;
  @override
  final Expression flutterSdkChannel;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestProject;
  final Expression integrationTestCacheConfig;

  WebIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required this.flutterSdkChannel,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
  });

  @override
  JobId get id => const JobId('integration_tests_web');

  @override
  Job build() => Job(
        name: 'Integration tests (web)',
        ifExpression: integrationTestPaths.ne(Expression.empty) &
            EnabledPlatforms.check(
              enabledPlatformsOutput.expression,
              Expression.literal(FlutterPlatform.web.platform),
            ),
        needs: {
          enabledPlatformsOutput.jobId,
        },
        runsOn: FlutterPlatform.web.os.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.web.platform),
          ),
          ...WebIntegrationTestBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestProject: integrationTestProject,
            integrationTestCacheConfig: integrationTestCacheConfig,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
