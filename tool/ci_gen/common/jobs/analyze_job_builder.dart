import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../steps/analyze_builder.dart';
import '../steps/project_prepare_builder.dart';
import '../steps/project_setup_builder.dart';
import '../steps/run_publish_builder.dart';
import '../steps/update_overrides_builder.dart';
import 'sdk_job_builder.dart';

base class AnalyzeJobConfig extends JobConfig
    with
        SdkJobConfig,
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        RunPublishConfig,
        AnalyzeConfig {
  final Expression analyzeImage;

  AnalyzeJobConfig({
    required Expression workingDirectory,
    required Expression artifactDependencies,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression removePubspecOverrides,
    required this.analyzeImage,
    required Expression localResolution,
    required Expression panaScoreThreshold,
  }) {
    this.workingDirectory = workingDirectory;
    this.artifactDependencies = artifactDependencies;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.removePubspecOverrides =
        ExpressionOrValue.expression(removePubspecOverrides);
    this.localResolution = ExpressionOrValue.expression(localResolution);
    this.panaScoreThreshold = panaScoreThreshold;
    expand();
  }
}

abstract base class AnalyzeJobBuilder<TConfig extends AnalyzeJobConfig>
    extends SdkJobBuilder<TConfig> {
  const AnalyzeJobBuilder({
    required super.config,
  });

  @override
  JobId get id => const JobId('analyze');

  JobIdOutput get platformsOutput => id.output('platforms');

  @override
  Job build() => Job(
        name: 'Analyze',
        runsOn: config.analyzeImage.toString(),
        outputs: {
          platformsOutput: AnalyzeBuilder.platformsOutput,
        },
        steps: [
          ...buildSetupSdkSteps(),
          ...AnalyzeBuilder(
            config: config,
            buildAnalyzeStep: buildAnalyzeSteps,
          ).build(),
        ],
      );

  @protected
  Iterable<Step> buildAnalyzeSteps();
}
