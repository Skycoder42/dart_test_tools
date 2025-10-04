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
import '../steps/build_macos_dmg_builder.dart';

final class BuildMacosJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig,
        BuildAppConfig,
        BuildMacosDmgConfig,
        FlutterSdkJobConfig {
  BuildMacosJobConfig(super.inputContext, super.secretContext);
}

final class BuildMacosJobBuilder extends SdkJobBuilder<BuildMacosJobConfig>
    with FlutterSdkJobBuilderMixin<BuildMacosJobConfig> {
  const BuildMacosJobBuilder({required super.config});

  @override
  JobId get id => const JobId('build_macos');

  @override
  Job build() => Job(
    name: 'Build macos dmg image',
    runsOn: RunsOn.macosLatest.id,
    steps: [
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(FlutterPlatform.macos.platform),
      ),
      ...BuildMacosDmgBuilder(config: config).build(),
    ],
  );
}
