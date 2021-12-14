import '../../common/api/workflow_input.dart';
import '../../common/builders/sdk_job_builder.dart';
import '../../common/inputs.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

mixin DartSdkJobBuilderMixin on SdkJobBuilder {
  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';

  @override
  Iterable<WorkflowInput> get setupSdkInputs => const [
        WorkflowInputs.dartSdkVersion,
      ];

  @override
  Iterable<Step> buildSetupSdkSteps([Expression? ifExpression]) => [
        Step.uses(
          name: 'Install Dart-SDK '
              '(${WorkflowInputs.dartSdkVersion.expression})',
          ifExpression: ifExpression,
          uses: 'dart-lang/setup-dart@v1.3',
          withArgs: {
            'sdk': WorkflowInputs.dartSdkVersion.expression.toString(),
          },
        )
      ];
}
