import '../../common/api/workflow_input.dart';
import '../../common/builders/analyze_job_builder.dart';
import '../../common/inputs.dart';
import '../../types/step.dart';
import 'dart_sdk_job_builder_mixin.dart';

class DartAnalyzeJobBuilder extends AnalyzeJobBuilder
    with DartSdkJobBuilderMixin {
  const DartAnalyzeJobBuilder();

  @override
  Iterable<WorkflowInput> get inputs => [
        ...super.inputs,
        WorkflowInputs.workingDirectory,
      ];

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'dart analyze --fatal-infos',
          workingDirectory:
              WorkflowInputs.workingDirectory.expression.toString(),
        )
      ];
}
