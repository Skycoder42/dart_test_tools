import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../flutter_platform.dart';
import '../steps/ios_integration_test_builder.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class IosIntegrationTestJobBuilder extends SdkJobBuilder
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
  final Expression browserStackIosDevices;
  final Expression browserStackCredentials;
  final Expression encodedProvisioningProfile;
  final Expression encodedSigningIdentity;
  final Expression signingIdentityPassphrase;

  IosIntegrationTestJobBuilder({
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
    required this.browserStackIosDevices,
    required this.browserStackCredentials,
    required this.encodedProvisioningProfile,
    required this.encodedSigningIdentity,
    required this.signingIdentityPassphrase,
  });

  @override
  JobId get id => const JobId('integration_tests_ios');

  @override
  Job build() => Job(
        name: 'Integration tests (ios)',
        ifExpression: integrationTestPaths.ne(Expression.empty) &
            EnabledPlatforms.check(
              enabledPlatformsOutput.expression,
              Expression.literal(FlutterPlatform.ios.platform),
            ),
        needs: {
          enabledPlatformsOutput.jobId,
        },
        runsOn: FlutterPlatform.ios.os.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.ios.platform),
          ),
          ...IosIntegrationTestBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestProject: integrationTestProject,
            integrationTestCacheConfig: integrationTestCacheConfig,
            browserStackIosDevices: browserStackIosDevices,
            browserStackCredentials: browserStackCredentials,
            encodedProvisioningProfile: encodedProvisioningProfile,
            encodedSigningIdentity: encodedSigningIdentity,
            signingIdentityPassphrase: signingIdentityPassphrase,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
