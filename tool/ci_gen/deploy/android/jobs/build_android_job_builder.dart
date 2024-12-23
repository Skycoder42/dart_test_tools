import '../../../common/api/job_config.dart';
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
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig,
        BuildAppConfig,
        BuildAndroidAppConfig,
        FlutterSdkJobConfig {
  BuildAndroidJobConfig({
    required Expression flutterSdkChannel,
    required Expression javaJdkVersion,
    required Expression workingDirectory,
    required Expression removePubspecOverrides,
    required Expression localResolution,
    required Expression artifactDependencies,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression buildNumberArgs,
    required Expression primaryLocale,
    required Expression dartDefines,
    required Expression keystore,
    required Expression keystorePassword,
  }) {
    this.flutterSdkChannel = flutterSdkChannel;
    this.javaJdkVersion = javaJdkVersion;
    this.workingDirectory = workingDirectory;
    this.removePubspecOverrides =
        ExpressionOrValue.expression(removePubspecOverrides);
    this.localResolution = ExpressionOrValue.expression(localResolution);
    this.artifactDependencies = artifactDependencies;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.buildNumberArgs = buildNumberArgs;
    this.primaryLocale = primaryLocale;
    this.dartDefines = dartDefines;
    this.keystore = keystore;
    this.keystorePassword = keystorePassword;
    expand();
  }
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
