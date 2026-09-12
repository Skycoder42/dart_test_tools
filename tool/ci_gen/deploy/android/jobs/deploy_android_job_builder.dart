import '../../../common/api/job_builder.dart';
import '../../../common/api/job_config.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/environments.dart';
import '../../../common/steps/resolve_artifact_prefix_builder.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_android_app_builder.dart';

final class DeployAndroidJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with
        WorkingDirectoryConfig,
        ResolveArtifactPrefixConfig,
        DeployAndroidConfig;

final class const DeployAndroidJobBuilder({
  required final DeployAndroidJobConfig config,
}) implements JobBuilder {
  @override
  JobId get id => const JobId('deploy_android');

  @override
  Job build() => Job(
    name: 'Deploy android app to Google Play',
    runsOn: RunsOn.macosLatest.id,
    environment: Environments.googlePlay,
    steps: [...DeployAndroidAppBuilder(config: config).build()],
  );
}
