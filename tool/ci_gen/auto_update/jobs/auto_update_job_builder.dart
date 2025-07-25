import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/install_tools_builder.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/auto_update_builder.dart';

final class AutoUpdateJobConfig extends JobConfig
    with
        SdkJobConfig,
        FlutterSdkJobConfig,
        InstallToolsConfig,
        WorkingDirectoryConfig,
        AutoUpdateConfig {
  AutoUpdateJobConfig(super.inputContext, super.secretContext);
}

final class AutoUpdateJobBuilder extends SdkJobBuilder<AutoUpdateJobConfig>
    with FlutterSdkJobBuilderMixin {
  final JobIdOutput needsUpdate;

  AutoUpdateJobBuilder({required this.needsUpdate, required super.config});

  @override
  JobId get id => const JobId('auto-update');

  @override
  Job build() => Job(
    name: 'Automatic dependency updates',
    needs: {needsUpdate.jobId},
    ifExpression: needsUpdate.expression.eq(const Expression.literal('true')),
    runsOn: RunsOn.ubuntuLatest.id,
    permissions: const {'contents': 'write', 'pull-requests': 'write'},
    steps: [
      ...buildSetupSdkSteps(),
      ...AutoUpdateBuilder(config: config).build(),
    ],
  );
}
