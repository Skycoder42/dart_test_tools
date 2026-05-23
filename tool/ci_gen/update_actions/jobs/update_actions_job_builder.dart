import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/update_actions_builder.dart';

final class UpdateActionsJobConfig extends JobConfig
    with
        SdkJobConfig,
        DartSdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        UpdateActionsConfig {
  UpdateActionsJobConfig(super.inputContext, super.secretContext);
}

final class UpdateActionsJobBuilder
    extends SdkJobBuilder<UpdateActionsJobConfig>
    with DartSdkJobBuilderMixin<UpdateActionsJobConfig> {
  const UpdateActionsJobBuilder({required super.config});

  @override
  JobId get id => const JobId('update-actions');

  @override
  Job build() => Job(
    name: 'Update GitHub Action versions',
    runsOn: RunsOn.ubuntuLatest.id,
    permissions: const {
      'contents': 'write',
      'pull-requests': 'write',
      'actions': 'write',
    },
    steps: [
      ...buildSetupSdkSteps(),
      ...UpdateActionsBuilder(config: config).build(),
    ],
  );
}
