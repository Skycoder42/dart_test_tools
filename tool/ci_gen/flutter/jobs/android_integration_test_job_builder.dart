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
import '../steps/setup_gcloud_builder.dart';
import 'common_integration_test_config.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class AndroidIntegrationTestJobConfig
    extends CommonIntegrationTestJobConfig
    with SetupGCloudConfig, AndroidIntegrationTestConfig {
  @override
  late final javaJdkVersion = inputContext(WorkflowInputs.javaJdkVersion);

  AndroidIntegrationTestJobConfig(super.inputContext, super.secretContext);
}

final class AndroidIntegrationTestJobBuilder
    extends SdkJobBuilder<AndroidIntegrationTestJobConfig>
    with FlutterSdkJobBuilderMixin<AndroidIntegrationTestJobConfig> {
  final JobIdOutput enabledPlatformsOutput;

  AndroidIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required super.config,
  });

  @override
  JobId get id => const JobId('integration_tests_android');

  @override
  Job build() => Job(
    name: 'Integration tests (android)',
    ifExpression:
        config.integrationTestPaths.ne(Expression.empty) &
        EnabledPlatforms.check(
          enabledPlatformsOutput.expression,
          Expression.literal(FlutterPlatform.android.platform),
        ) &
        config.firebaseProjectId.ne(Expression.empty),
    needs: {enabledPlatformsOutput.jobId},
    runsOn: FlutterPlatform.android.os.id,
    steps: [
      ...ValidateInputsBuilder({
        WorkflowSecrets.firebaseCredentials.name: config.firebaseCredentials,
      }).build(),
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(
          FlutterPlatform.android.platform,
        ),
      ),
      ...AndroidIntegrationTestBuilder(config: config).build(),
    ],
  );
}
