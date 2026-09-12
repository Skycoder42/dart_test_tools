import '../../../common/api/job_config.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/steps/project_prepare_builder.dart';
import '../../../common/steps/project_setup_builder.dart';
import '../../../common/steps/resolve_artifact_prefix_builder.dart';
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

final class BuildMacosJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig,
        ResolveArtifactPrefixConfig,
        BuildAppConfig,
        BuildMacosDmgConfig,
        FlutterSdkJobConfig;

final class const BuildMacosJobBuilder({required super.config})
    extends SdkJobBuilder<BuildMacosJobConfig>
    with FlutterSdkJobBuilderMixin<BuildMacosJobConfig> {
  @override
  JobId get id => const JobId('build_macos');

  JobIdOutput get artifactNameOutput => id.output('artifact-name');

  @override
  Job build() => Job(
    name: 'Build macos dmg image',
    runsOn: RunsOn.macosLatest.id,
    outputs: {artifactNameOutput: BuildAppBuilder.artifactNameOutput},
    steps: [
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(FlutterPlatform.macos.platform),
      ),
      ...BuildMacosDmgBuilder(config: config).build(),
    ],
  );
}
