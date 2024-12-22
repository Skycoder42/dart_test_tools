import '../../common/api/job_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/jobs/unit_test_job_builder.dart';
import '../../common/steps/coverage_builder_mixin.dart';
import '../../common/steps/coverage_collector_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/unit_test_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../types/expression.dart';
import '../dart_platform.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartUnitTestJobConfig extends JobConfig
    with
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        CoverageBuilderConfig,
        CoverageCollectorConfig,
        UnitTestConfig,
        SdkJobConfig,
        UnitTestJobConfig,
        DartSdkJobConfig {
  DartUnitTestJobConfig({
    required Expression workingDirectory,
    required Expression artifactDependencies,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression removePubspecOverrides,
    required Expression localResolution,
    required Expression unitTestPaths,
    required Expression minCoverage,
    required Expression dartSdkVersion,
  }) {
    this.workingDirectory = workingDirectory;
    this.artifactDependencies = artifactDependencies;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.removePubspecOverrides =
        ExpressionOrValue.expression(removePubspecOverrides);
    this.localResolution = ExpressionOrValue.expression(localResolution);
    this.unitTestPaths = unitTestPaths;
    this.minCoverage = minCoverage;
    this.dartSdkVersion = dartSdkVersion;
    coverageArgs = '--coverage=coverage';
    needsFormatting = true;
    expand();
  }
}

final class DartUnitTestJobBuilder
    extends UnitTestJobBuilder<DartUnitTestJobConfig>
    with DartSdkJobBuilderMixin<DartUnitTestJobConfig> {
  DartUnitTestJobBuilder({
    required super.enabledPlatformsOutput,
    required super.config,
  }) : super(platformSelectors: DartPlatform.values);
}
