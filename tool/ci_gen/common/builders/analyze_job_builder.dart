import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/job.dart';
import '../../types/step.dart';
import '../api/job_builder.dart';
import '../api/workflow_input.dart';
import '../inputs.dart';
import '../steps/analyze_builder.dart';
import 'sdk_job_builder.dart';

abstract class AnalyzeJobBuilder extends SdkJobBuilder {
  const AnalyzeJobBuilder();

  @override
  String get name => 'analyze';

  @override
  Iterable<WorkflowInput> get inputs => [
        ...setupSdkInputs,
        WorkflowInputs.repository,
        WorkflowInputs.workingDirectory,
        WorkflowInputs.buildRunner,
        WorkflowInputs.analyzeImage,
        WorkflowInputs.publishExclude,
      ];

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Analyze',
        runsOn: WorkflowInputs.analyzeImage.expression.toString(),
        needs: needs?.map((jobBuilder) => jobBuilder.name).toList(),
        steps: [
          ...buildSetupSdkSteps(),
          ...AnalyzeBuilder(
            repository: WorkflowInputs.repository.expression,
            workingDirectory: WorkflowInputs.workingDirectory.expression,
            buildRunner: WorkflowInputs.buildRunner.expression,
            analyzeImage: WorkflowInputs.analyzeImage.expression,
            publishExclude: WorkflowInputs.publishExclude.expression,
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
