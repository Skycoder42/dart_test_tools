import '../../common/api/job_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/package_builder.dart';

final class PackageJobConfig extends JobConfig
    with
        SdkJobConfig,
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        PackageConfig,
        DartSdkJobConfig {
  PackageJobConfig({
    required Expression dartSdkVersion,
    required Expression workingDirectory,
    required Expression artifactDependencies,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression removePubspecOverrides,
  }) {
    this.dartSdkVersion = dartSdkVersion;
    this.workingDirectory = workingDirectory;
    this.artifactDependencies = artifactDependencies;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.removePubspecOverrides =
        ExpressionOrValue.expression(removePubspecOverrides);
    localResolution = const ExpressionOrValue.value(true);
    expand();
  }
}

final class PackageJobBuilder extends SdkJobBuilder<PackageJobConfig>
    with DartSdkJobBuilderMixin<PackageJobConfig> {
  @override
  JobId get id => const JobId('package');

  PackageJobBuilder({
    required super.config,
  });

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
