import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../steps/analyze_builder.dart';
import 'sdk_job_builder.dart';

base mixin AnalyzeJobConfig on JobConfig, AnalyzeConfig, SdkJobConfig {
  late Expression analyzeImage;
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
