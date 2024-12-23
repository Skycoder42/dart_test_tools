import '../../../common/api/job_config.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/inputs.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/steps/project_prepare_builder.dart';
import '../../../common/steps/project_setup_builder.dart';
import '../../../common/steps/update_overrides_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../../steps/build_app_builder.dart';
import '../../steps/flutter_build_builder.dart';
import '../../steps/generate_build_number_builder.dart';
import '../steps/build_android_app_builder.dart';

final class BuildAndroidJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig,
        BuildAppConfig,
        BuildAndroidAppConfig,
        FlutterSdkJobConfig {
  @override
  late final javaJdkVersion = inputContext(WorkflowInputs.javaJdkVersion);

  BuildAndroidJobConfig(super.inputContext, super.secretContext);
}

final class BuildAndroidJobBuilder extends SdkJobBuilder<BuildAndroidJobConfig>
    with FlutterSdkJobBuilderMixin<BuildAndroidJobConfig> {
  const BuildAndroidJobBuilder({
    required super.config,
  });

  @override
  JobId get id => const JobId('build_android');

  @override
  Job build() => Job(
        name: 'Build android app bundle',
        runsOn: RunsOn.ubuntuLatest.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.android.platform),
          ),
          ...BuildAndroidAppBuilder(config: config).build(),
        ],
      );
}
