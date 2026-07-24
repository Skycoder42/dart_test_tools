import '../../../common/api/job_builder.dart';
import '../../../common/api/job_config.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/environments.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/resolve_artifact_prefix_builder.dart';
import '../../../common/steps/validate_inputs_builder.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_android_app_builder.dart';

final class DeployAndroidJobConfig extends JobConfig
    with
        WorkingDirectoryConfig,
        ResolveArtifactPrefixConfig,
        DeployAndroidConfig {
  DeployAndroidJobConfig(super.inputContext, super.secretContext);
}

final class DeployAndroidJobBuilder implements JobBuilder {
  final DeployAndroidJobConfig config;

  const DeployAndroidJobBuilder({required this.config});

  @override
  JobId get id => const JobId('deploy_android');

  @override
  Job build() => Job(
    name: 'Deploy android app to Google Play',
    runsOn: RunsOn.macosLatest.id,
    environment: Environments.googlePlay,
    steps: [
      ...ValidateInputsBuilder({
        WorkflowSecrets.googlePlayKey.name: config.googlePlayKey,
      }).build(),
      ...DeployAndroidAppBuilder(config: config).build(),
    ],
  );
}
