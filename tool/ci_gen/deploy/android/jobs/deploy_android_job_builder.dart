import '../../../common/api/job_builder.dart';
import '../../../common/api/job_config.dart';
import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/environments.dart';
import '../../../common/inputs.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/validate_inputs_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_android_app_builder.dart';

final class DeployAndroidJobConfig extends JobConfig
    with WorkingDirectoryConfig, DeployAndroidConfig {
  late final enabledPlatforms = inputContext(WorkflowInputs.enabledPlatforms);

  DeployAndroidJobConfig(super.inputContext, super.secretContext);
}

final class DeployAndroidJobBuilder implements JobBuilder {
  final JobIdOutput releaseCreated;
  final DeployAndroidJobConfig config;

  const DeployAndroidJobBuilder({
    required this.releaseCreated,
    required this.config,
  });

  @override
  JobId get id => const JobId('deploy_android');

  @override
  Job build() => Job(
        name: 'Deploy android app to Google Play',
        runsOn: RunsOn.macosLatest.id,
        needs: {releaseCreated.jobId},
        ifExpression:
            releaseCreated.expression.eq(const Expression.literal('true')) &
                EnabledPlatforms.check(
                  config.enabledPlatforms,
                  Expression.literal(FlutterPlatform.android.platform),
                ),
        environment: Environments.googlePlay,
        steps: [
          ...ValidateInputsBuilder({
            WorkflowSecrets.googlePlayKey.name: config.googlePlayKey,
          }).build(),
          ...DeployAndroidAppBuilder(config: config).build(),
        ],
      );
}
