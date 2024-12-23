import '../../common/jobs/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartAnalyzeJobConfig extends AnalyzeJobConfig
    with DartSdkJobConfig {
  DartAnalyzeJobConfig({
    required super.workingDirectory,
    required super.artifactDependencies,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.removePubspecOverrides,
    required super.analyzeImage,
    required super.localResolution,
    required super.panaScoreThreshold,
    required Expression dartSdkVersion,
  }) {
    this.dartSdkVersion = dartSdkVersion;
  }
}

final class DartAnalyzeJobBuilder
    extends AnalyzeJobBuilder<DartAnalyzeJobConfig>
    with DartSdkJobBuilderMixin<DartAnalyzeJobConfig> {
  const DartAnalyzeJobBuilder({
    required super.config,
  });

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'dart analyze --fatal-infos',
          workingDirectory: config.workingDirectory.toString(),
        ),
      ];
}
