import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/check_update_required_builder.dart';

final class CheckUpdateRequiredJobConfig(
  super.inputContext,
  super.secretContext,
) extends JobConfig
    with
        SdkJobConfig,
        FlutterSdkJobConfig,
        WorkingDirectoryConfig,
        CheckUpdateRequiredConfig;

final class CheckUpdateRequiredJobBuilder({required super.config})
    extends SdkJobBuilder<CheckUpdateRequiredJobConfig>
    with FlutterSdkJobBuilderMixin {
  @override
  JobId get id => const JobId('check-update-required');

  JobIdOutput get needsUpdate => id.output('needs_update');

  @override
  Job build() => Job(
    name: 'Check if updates are required',
    runsOn: RunsOn.ubuntuLatest.id,
    outputs: {needsUpdate: CheckUpdateRequiredBuilder.needsUpdate},
    steps: [
      ...buildSetupSdkSteps(),
      ...CheckUpdateRequiredBuilder(config: config).build(),
    ],
  );
}
