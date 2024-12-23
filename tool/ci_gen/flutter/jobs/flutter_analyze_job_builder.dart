import '../../common/jobs/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterAnalyzeJobConfig extends AnalyzeJobConfig
    with FlutterSdkJobConfig {
  FlutterAnalyzeJobConfig({
    required super.workingDirectory,
    required super.artifactDependencies,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.removePubspecOverrides,
    required super.analyzeImage,
    required super.localResolution,
    required super.panaScoreThreshold,
    required Expression flutterSdkChannel,
    required Expression javaJdkVersion,
  }) {
    this.flutterSdkChannel = flutterSdkChannel;
    this.javaJdkVersion = javaJdkVersion;
  }
}

final class FlutterAnalyzeJobBuilder
    extends AnalyzeJobBuilder<FlutterAnalyzeJobConfig>
    with FlutterSdkJobBuilderMixin<FlutterAnalyzeJobConfig> {
  const FlutterAnalyzeJobBuilder({
    required super.config,
  });

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'flutter analyze',
          workingDirectory: config.workingDirectory.toString(),
        ),
      ];
}
