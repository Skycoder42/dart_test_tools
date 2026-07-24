import '../../../common/api/job_builder.dart';
import '../../../common/api/job_config.dart';
import '../../../common/environments.dart';
import '../../../common/inputs.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/validate_inputs_builder.dart';
import '../../../types/container.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_to_pages_builder.dart';
import '../steps/with_gpg_key.dart';

final class DeployLinuxJobConfig extends JobConfig
    with WithGpgKeyConfig, DeployToPagesConfig {
  late final flatpakPlatformImage = inputContext(
    WorkflowInputs.flatpakPlatformImage,
  );

  DeployLinuxJobConfig(super.inputContext, super.secretContext);
}

final class DeployLinuxJobBuilder implements JobBuilder {
  final DeployLinuxJobConfig config;

  DeployLinuxJobBuilder({required this.config});

  @override
  JobId get id => const JobId('deploy_linux');

  @override
  Job build() => Job(
    name: 'Deploy flatpak bundles to GitHub Pages',
    runsOn: RunsOn.ubuntuLatest.id,
    container: Container(
      image: config.flatpakPlatformImage.toString(),
      options: '--privileged',
    ),
    environment: Environments.flatpak,
    permissions: const {'contents': 'write'},
    steps: [
      ...ValidateInputsBuilder({
        WorkflowSecrets.gpgKeyId(false).name: config.gpgKeyId,
        WorkflowSecrets.gpgKey(false).name: config.gpgKey,
      }).build(),
      ...DeployToPagesBuilder(config: config).build(),
    ],
  );
}
