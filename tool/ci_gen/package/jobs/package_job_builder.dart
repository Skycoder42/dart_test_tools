import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/package_builder.dart';

final class PackageJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        PackageConfig,
        DartSdkJobConfig;

final class PackageJobBuilder({required super.config})
    extends SdkJobBuilder<PackageJobConfig>
    with DartSdkJobBuilderMixin<PackageJobConfig> {
  @override
  JobId get id => const JobId('package');

  @override
  Job build() => Job(
    name: 'Create dart package artifact',
    runsOn: 'ubuntu-latest',
    steps: [
      ...buildSetupSdkSteps(),
      ...PackageBuilder(config: config).build(),
    ],
  );
}
