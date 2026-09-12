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

abstract base class AnalyzeJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        RunPublishConfig,
        AnalyzeConfig {
  late final analyzeImage = inputContext(WorkflowInputs.analyzeImage);
}

abstract base class const AnalyzeJobBuilder<TConfig extends AnalyzeJobConfig>({
  required super.config,
}) extends SdkJobBuilder<TConfig> {
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
