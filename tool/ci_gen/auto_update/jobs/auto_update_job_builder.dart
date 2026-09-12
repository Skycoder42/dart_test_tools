import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/auto_update_builder.dart';

final class AutoUpdateJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with
        SdkJobConfig,
        FlutterSdkJobConfig,
        WorkingDirectoryConfig,
        AutoUpdateConfig;

final class AutoUpdateJobBuilder({
  required final JobIdOutput needsUpdate,
  required super.config,
}) extends SdkJobBuilder<AutoUpdateJobConfig> with FlutterSdkJobBuilderMixin {
  @override
  JobId get id => const JobId('auto-update');

  @override
  Job build() => Job(
    name: 'Automatic dependency updates',
    needs: {needsUpdate.jobId},
    ifExpression: needsUpdate.expression.eq(const Expression.literal('true')),
    runsOn: RunsOn.ubuntuLatest.id,
    permissions: const {
      'contents': 'write',
      'pull-requests': 'write',
      'actions': 'write',
    },
    steps: [
      ...buildSetupSdkSteps(),
      ...AutoUpdateBuilder(config: config).build(),
    ],
  );
}
