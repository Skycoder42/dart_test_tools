import '../../common/api/job_config.dart';
import '../../common/contexts.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/renovate_builder.dart';

final class RenovateJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with SdkJobConfig, FlutterSdkJobConfig, RenovateConfig;

final class const RenovateJobBuilder({required super.config})
    extends SdkJobBuilder<RenovateJobConfig>
    with FlutterSdkJobBuilderMixin<RenovateJobConfig> {
  @override
  JobId get id => const JobId('renovate');

  @override
  Job build() => Job(
    name: 'Renovate',
    runsOn: RunsOn.ubuntuLatest.id,
    permissions: const {
      'contents': 'write',
      'pull-requests': 'write',
      'issues': 'write',
      'statuses': 'write',
    },
    concurrency: 'renovate-${Github.repository}',
    steps: [
      ...buildSetupSdkSteps(),
      ...RenovateBuilder(config: config).build(),
    ],
  );
}
