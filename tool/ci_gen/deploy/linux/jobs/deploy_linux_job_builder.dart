import '../../../common/api/job_builder.dart';
import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/environments.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../types/container.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_to_pages_builder.dart';

class DeployLinuxJobBuilder implements JobBuilder {
  final JobIdOutput releaseCreated;
  final Expression enabledPlatforms;
  final Expression sdkVersion;
  final Expression gpgKeyId;
  final Expression gpgKey;

  DeployLinuxJobBuilder({
    required this.releaseCreated,
    required this.enabledPlatforms,
    required this.sdkVersion,
    required this.gpgKeyId,
    required this.gpgKey,
  });

  @override
  JobId get id => const JobId('deploy_linux');

  @override
  Job build() => Job(
        name: 'Deploy flatpak bundles to GitHub Pages',
        needs: {releaseCreated.jobId},
        runsOn: RunsOn.ubuntuLatest.id,
        container: Container(
          image:
              'bilelmoussaoui/flatpak-github-actions:freedesktop-$sdkVersion',
          options: '--privileged',
        ),
        ifExpression:
            releaseCreated.expression.eq(const Expression.literal('true')) &
                EnabledPlatforms.check(
                  enabledPlatforms,
                  Expression.literal(FlutterPlatform.linux.platform),
                ),
        environment: Environments.flatpak,
        permissions: const {
          'contents': 'write',
        },
        steps: [
          ...DeployToPagesBuilder(
            gpgKeyId: gpgKeyId,
            gpgKey: gpgKey,
          ).build(),
        ],
      );
}
