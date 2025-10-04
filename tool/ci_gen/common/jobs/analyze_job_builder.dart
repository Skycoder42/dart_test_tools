import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/working_directory_config.dart';
import '../inputs.dart';
import '../steps/analyze_builder.dart';
import '../steps/project_prepare_builder.dart';
import '../steps/project_setup_builder.dart';
import '../steps/run_publish_builder.dart';
import 'sdk_job_builder.dart';

abstract base class AnalyzeJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        RunPublishConfig,
        AnalyzeConfig {
  late final analyzeImage = inputContext(WorkflowInputs.analyzeImage);

  AnalyzeJobConfig(super.inputContext, super.secretContext);
}

abstract base class AnalyzeJobBuilder<TConfig extends AnalyzeJobConfig>
    extends SdkJobBuilder<TConfig> {
  const AnalyzeJobBuilder({required super.config});

  @override
  JobId get id => const JobId('analyze');

  JobIdOutput get platformsOutput => id.output('platforms');

  @override
  Job build() => Job(
    name: 'Analyze',
    runsOn: config.analyzeImage.toString(),
    outputs: {platformsOutput: AnalyzeBuilder.platformsOutput},
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
