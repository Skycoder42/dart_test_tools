import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/package_builder.dart';

final class PackageJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        PackageConfig,
        DartSdkJobConfig {
  PackageJobConfig(super.inputContext, super.secretContext);
}

final class PackageJobBuilder extends SdkJobBuilder<PackageJobConfig>
    with DartSdkJobBuilderMixin<PackageJobConfig> {
  @override
  JobId get id => const JobId('package');

  PackageJobBuilder({required super.config});

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
