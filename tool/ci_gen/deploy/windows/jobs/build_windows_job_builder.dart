import '../../../common/api/job_config.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/steps/project_prepare_builder.dart';
import '../../../common/steps/project_setup_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../../steps/build_app_builder.dart';
import '../../steps/flutter_build_builder.dart';
import '../../steps/generate_build_number_builder.dart';
import '../steps/build_windows_installer_builder.dart';

final class BuildWindowsJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig,
        BuildAppConfig,
        BuildWindowsInstallerConfig,
        FlutterSdkJobConfig {
  BuildWindowsJobConfig(super.inputContext, super.secretContext);
}

final class BuildWindowsJobBuilder extends SdkJobBuilder<BuildWindowsJobConfig>
    with FlutterSdkJobBuilderMixin<BuildWindowsJobConfig> {
  const BuildWindowsJobBuilder({required super.config});

  @override
  JobId get id => const JobId('build_windows');

  @override
  Job build() => Job(
    name: 'Build windows msix installer',
    runsOn: RunsOn.windowsLatest.id,
    steps: [
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(
          FlutterPlatform.windows.platform,
        ),
      ),
      ...BuildWindowsInstallerBuilder(config: config).build(),
    ],
  );
}
