import '../../common/api/platform_matrix_job_builder_mixin.dart';
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
  IosIntegrationTestJobConfig(super.inputContext, super.secretContext);
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
    ifExpression:
        config.integrationTestPaths.ne(Expression.empty) &
        EnabledPlatforms.check(
          enabledPlatformsOutput.expression,
          Expression.literal(FlutterPlatform.ios.platform),
        ) &
        config.firebaseProjectId.ne(Expression.empty),
    needs: {enabledPlatformsOutput.jobId},
    runsOn: FlutterPlatform.ios.os.id,
    steps: [
      ...ValidateInputsBuilder({
        WorkflowSecrets.provisioningProfile.name:
            config.encodedProvisioningProfile,
        WorkflowSecrets.signingIdentity.name: config.encodedSigningIdentity,
        WorkflowSecrets.signingIdentityPassphrase.name:
            config.signingIdentityPassphrase,
        WorkflowSecrets.firebaseCredentials.name: config.firebaseCredentials,
      }).build(),
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(FlutterPlatform.ios.platform),
      ),
      ...IosIntegrationTestBuilder(config: config).build(),
    ],
  );
}
