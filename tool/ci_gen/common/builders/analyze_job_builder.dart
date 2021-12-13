import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/job.dart';
import '../../types/step.dart';
import '../api/job_builder.dart';
import '../api/workflow_input.dart';
import '../inputs.dart';
import '../steps/analyze_builder.dart';
import 'sdk_job_builder.dart';

abstract class AnalyzeJobBuilder extends SdkJobBuilder {
  @override
  String get name => 'analyze';

  @override
  Iterable<WorkflowInput> get inputs => [
        ...setupSdkInputs,
        WorkflowInputs.repositoryInput,
        WorkflowInputs.workingDirectoryInput,
        WorkflowInputs.buildRunnerInput,
        WorkflowInputs.analyzeImageInput,
        WorkflowInputs.publishExcludeInput,
      ];

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Analyze',
        runsOn: Expression.input(WorkflowInputs.analyzeImageInput),
        needs: needs?.map((jobBuilder) => jobBuilder.name).toList(),
        steps: [
          ...buildSetupSdkSteps(),
          ...AnalyzeBuilder(
            repository: WorkflowInputs.repositoryInput,
            workingDirectory: WorkflowInputs.workingDirectoryInput,
            buildRunner: WorkflowInputs.buildRunnerInput,
            analyzeImage: WorkflowInputs.analyzeImageInput,
            publishExclude: WorkflowInputs.publishExcludeInput,
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
