import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/step.dart';
import '../api/workflow_input.dart';
import 'project_setup_builder_mixin.dart';

mixin AnalyzeBuilderMixin on ProjectSetupBuilderMixin {
  @protected
  final analyzeImageInput = const WorkflowInput(
    name: 'analyzeImage',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'ubuntu-latest',
      description: 'The Runner-Image to use for the analyze step. '
          'Uses ubuntu-latest by default',
    ),
  );

  @protected
  final publishExcludeInput = const WorkflowInput(
    name: 'publishExclude',
    input: Input(
      type: Type.string,
      required: false,
      description: 'Specify a list of colon separated paths to be excluded '
          'from publishing.',
    ),
  );

  @protected
  Step createAnalyzeStep();

  Iterable<WorkflowInput> get analyzeInputs => [
        analyzeImageInput,
        publishExcludeInput,
      ];

  Iterable<Step> createAnalyzeSteps() => [
        // Step.run(
        //   name: 'Install dart_test_tools',
        //   run: '$pubTool global activate dart_test_tools',
        // ),
        createAnalyzeStep(),
        // Step.run(
        //   name: 'Validate library imports',
        //   run: '$pubTool global run dart_test_tools:import_analyzer -lALL',
        //   workingDirectory: Expression.input(workingDirectoryInput),
        // ),
        Step.run(
          name: 'Validate correct formatting',
          run: '$baseTool format -onone --set-exit-if-changed .',
          workingDirectory: Expression.input(workingDirectoryInput),
        ),
        Step.run(
          name: 'Test publishing configuration',
          run: '''
set -e
if [[ ! -z "${Expression.input(publishExcludeInput)}" ]]; then
  IFS=':'
  for path in "${Expression.input(publishExcludeInput)}"; do
    if [ -e "\$path" ]; then
      git rm "\$path"
    fi
  done
fi
exec $pubTool publish --dry-run
''',
          workingDirectory: Expression.input(workingDirectoryInput),
          shell: 'bash',
        ),
      ];
}
