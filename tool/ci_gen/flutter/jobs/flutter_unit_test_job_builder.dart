import '../../common/jobs/unit_test_job_builder.dart';
import '../../dart/dart_platform.dart';
import '../../types/expression.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterUnitTestJobConfig extends UnitTestJobConfig
    with FlutterSdkJobConfig {
  FlutterUnitTestJobConfig({
    required super.workingDirectory,
    required super.artifactDependencies,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.removePubspecOverrides,
    required super.localResolution,
    required super.unitTestPaths,
    required super.minCoverage,
    required Expression flutterSdkChannel,
    required Expression javaJdkVersion,
  }) {
    this.flutterSdkChannel = flutterSdkChannel;
    this.javaJdkVersion = javaJdkVersion;
    coverageArgs = '--coverage';
    needsFormatting = false;
  }
}

final class FlutterUnitTestJobBuilder
    extends UnitTestJobBuilder<FlutterUnitTestJobConfig>
    with FlutterSdkJobBuilderMixin<FlutterUnitTestJobConfig> {
  FlutterUnitTestJobBuilder({
    required super.enabledPlatformsOutput,
    required super.config,
  }) : super(platformSelectors: DartPlatform.values);
}
