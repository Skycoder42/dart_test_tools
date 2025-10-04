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
import '../steps/build_web_archive_builder.dart';

final class BuildWebJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig,
        BuildAppConfig,
        BuildWebArchiveConfig,
        FlutterSdkJobConfig {
  BuildWebJobConfig(super.inputContext, super.secretContext);
}

final class BuildWebJobBuilder extends SdkJobBuilder<BuildWebJobConfig>
    with FlutterSdkJobBuilderMixin<BuildWebJobConfig> {
  const BuildWebJobBuilder({required super.config});

  @override
  JobId get id => const JobId('build_web');

  @override
  Job build() => Job(
    name: 'Build web archive',
    runsOn: RunsOn.ubuntuLatest.id,
    steps: [
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(FlutterPlatform.web.platform),
      ),
      ...BuildWebArchiveBuilder(config: config).build(),
    ],
  );
}
