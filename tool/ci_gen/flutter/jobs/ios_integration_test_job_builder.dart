import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/secrets.dart';
import '../../common/steps/validate_inputs_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../flutter_platform.dart';
import '../steps/install_xcode_signing_builder.dart';
import '../steps/ios_integration_test_builder.dart';
import '../steps/setup_gcloud_builder.dart';
import 'common_integration_test_config.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class IosIntegrationTestJobConfig extends CommonIntegrationTestJobConfig
    with
        InstallXcodeSigningConfig,
        SetupGCloudConfig,
        IosIntegrationTestConfig {
  IosIntegrationTestJobConfig({
    required super.flutterSdkChannel,
    required super.workingDirectory,
    required super.artifactDependencies,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.removePubspecOverrides,
    required super.localResolution,
    required super.integrationTestSetup,
    required super.integrationTestPaths,
    required super.integrationTestProject,
    required super.integrationTestCacheConfig,
    required Expression encodedProvisioningProfile,
    required Expression encodedSigningIdentity,
    required Expression signingIdentityPassphrase,
    required Expression firebaseProjectId,
    required Expression firebaseCredentials,
  }) {
    this.encodedProvisioningProfile = encodedProvisioningProfile;
    this.encodedSigningIdentity = encodedSigningIdentity;
    this.signingIdentityPassphrase = signingIdentityPassphrase;
    this.firebaseProjectId = firebaseProjectId;
    this.firebaseCredentials = firebaseCredentials;
  }
}

final class IosIntegrationTestJobBuilder
    extends SdkJobBuilder<IosIntegrationTestJobConfig>
    with FlutterSdkJobBuilderMixin<IosIntegrationTestJobConfig> {
  final JobIdOutput enabledPlatformsOutput;

  IosIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required super.config,
  });

  @override
  JobId get id => const JobId('integration_tests_ios');

  @override
  Job build() => Job(
        name: 'Integration tests (ios)',
        ifExpression: config.integrationTestPaths.ne(Expression.empty) &
            EnabledPlatforms.check(
              enabledPlatformsOutput.expression,
              Expression.literal(FlutterPlatform.ios.platform),
            ),
        needs: {
          enabledPlatformsOutput.jobId,
        },
        runsOn: FlutterPlatform.ios.os.id,
        steps: [
          ...ValidateInputsBuilder({
            WorkflowSecrets.provisioningProfile.name:
                config.encodedProvisioningProfile,
            WorkflowSecrets.signingIdentity.name: config.encodedSigningIdentity,
            WorkflowSecrets.signingIdentityPassphrase.name:
                config.signingIdentityPassphrase,
            WorkflowInputs.firebaseProjectId.name: config.firebaseProjectId,
            WorkflowSecrets.firebaseCredentials.name:
                config.firebaseCredentials,
          }).build(),
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.ios.platform),
          ),
          ...IosIntegrationTestBuilder(config: config).build(),
        ],
      );
}
