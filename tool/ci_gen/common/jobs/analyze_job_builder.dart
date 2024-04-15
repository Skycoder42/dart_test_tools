import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/step.dart';
import '../steps/analyze_builder.dart';
import 'sdk_job_builder.dart';

abstract base class AnalyzeJobBuilder extends SdkJobBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression analyzeImage;
  final Expression panaScoreThreshold;

  const AnalyzeJobBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.analyzeImage,
    required this.panaScoreThreshold,
  });

  @override
  JobId get id => const JobId('analyze');

  JobIdOutput get platformsOutput => id.output('platforms');

  @override
  Job build() => Job(
        name: 'Analyze',
        runsOn: analyzeImage.toString(),
        outputs: {
          platformsOutput: AnalyzeBuilder.platformsOutput,
        },
        steps: [
          ...buildSetupSdkSteps(),
          ...AnalyzeBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            analyzeImage: analyzeImage,
            panaScoreThreshold: panaScoreThreshold,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            buildAnalyzeStep: buildAnalyzeSteps,
          ).build(),
        ],
      );

  @protected
  Iterable<Step> buildAnalyzeSteps();
}
