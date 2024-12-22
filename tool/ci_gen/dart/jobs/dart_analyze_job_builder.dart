import '../../common/api/job_config.dart';
import '../../common/jobs/analyze_job_builder.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/analyze_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/run_publish_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartAnalyzeJobConfig extends JobConfig
    with
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        RunPublishConfig,
        AnalyzeConfig,
        SdkJobConfig,
        AnalyzeJobConfig,
        DartSdkJobConfig {
  DartAnalyzeJobConfig({
    required Expression workingDirectory,
    required Expression artifactDependencies,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression removePubspecOverrides,
    required Expression analyzeImage,
    required Expression localResolution,
    required Expression panaScoreThreshold,
    required Expression dartSdkVersion,
  }) {
    this.workingDirectory = workingDirectory;
    this.artifactDependencies = artifactDependencies;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.removePubspecOverrides =
        ExpressionOrValue.expression(removePubspecOverrides);
    this.analyzeImage = analyzeImage;
    this.localResolution = ExpressionOrValue.expression(localResolution);
    this.panaScoreThreshold = panaScoreThreshold;
    this.dartSdkVersion = dartSdkVersion;
    expand();
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
