import '../../common/jobs/unit_test_job_builder.dart';
import '../../types/expression.dart';
import '../dart_platform.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartUnitTestJobConfig extends UnitTestJobConfig
    with DartSdkJobConfig {
  DartUnitTestJobConfig({
    required super.workingDirectory,
    required super.artifactDependencies,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.removePubspecOverrides,
    required super.localResolution,
    required super.unitTestPaths,
    required super.minCoverage,
    required Expression dartSdkVersion,
  }) {
    this.dartSdkVersion = dartSdkVersion;
    coverageArgs = '--coverage=coverage';
    needsFormatting = true;
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
