import '../../../common/api/job_builder.dart';
import '../../../common/api/job_config.dart';
import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/environments.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/validate_inputs_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../types/container.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_to_pages_builder.dart';
import '../steps/with_gpg_key.dart';

final class DeployLinuxJobConfig extends JobConfig
    with WithGpgKeyConfig, DeployToPagesConfig {
  final Expression enabledPlatforms;
  final Expression flatpakPlatformImage;

  DeployLinuxJobConfig({
    required this.enabledPlatforms,
    required this.flatpakPlatformImage,
    required Expression gpgKeyId,
    required Expression gpgKey,
  }) {
    this.gpgKeyId = gpgKeyId;
    this.gpgKey = gpgKey;
    expand();
  }
}

class DeployLinuxJobBuilder implements JobBuilder {
  final JobIdOutput releaseCreated;
  final DeployLinuxJobConfig config;

  DeployLinuxJobBuilder({
    required this.releaseCreated,
    required this.config,
  });

  @override
  JobId get id => const JobId('deploy_linux');

  @override
  Job build() => Job(
        name: 'Deploy flatpak bundles to GitHub Pages',
        needs: {releaseCreated.jobId},
        runsOn: RunsOn.ubuntuLatest.id,
        container: Container(
          image: 'bilelmoussaoui/${config.flatpakPlatformImage}',
          options: '--privileged',
        ),
        ifExpression:
            releaseCreated.expression.eq(const Expression.literal('true')) &
                EnabledPlatforms.check(
                  config.enabledPlatforms,
                  Expression.literal(FlutterPlatform.linux.platform),
                ),
        environment: Environments.flatpak,
        permissions: const {
          'contents': 'write',
        },
        steps: [
          ...ValidateInputsBuilder({
            WorkflowSecrets.gpgKeyId(false).name: config.gpgKeyId,
            WorkflowSecrets.gpgKey(false).name: config.gpgKey,
          }).build(),
          ...DeployToPagesBuilder(config: config).build(),
        ],
      );
}
