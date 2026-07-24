import '../../../common/api/job_config.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/environments.dart';
import '../../../common/inputs.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/validate_inputs_builder.dart';
import '../../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_to_tap_builder.dart';

final class DeployMacosJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        DeployToTapConfig,
        DartSdkJobConfig {
  late final version = inputContext(WorkflowInputs.version);

  DeployMacosJobConfig(super.inputContext, super.secretContext);
}

final class DeployMacosJobBuilder extends SdkJobBuilder<DeployMacosJobConfig>
    with DartSdkJobBuilderMixin<DeployMacosJobConfig> {
  const DeployMacosJobBuilder({required super.config});

  @override
  JobId get id => const JobId('deploy_macos');

  @override
  Job build() => Job(
    name: 'Deploy DMG image to homebrew tap',
    runsOn: RunsOn.macosLatest.id,
    environment: Environments.homebrew,
    steps: [
      ...ValidateInputsBuilder({
        WorkflowInputs.targetRepo.name: config.targetRepo,
        WorkflowSecrets.targetRepoToken.name: config.targetRepoToken,
      }).build(),
      ...buildSetupSdkSteps(),
      ...DeployToTapBuilder(
        config: config,
        releaseVersion: config.version,
      ).build(),
    ],
  );
}
