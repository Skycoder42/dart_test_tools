import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../api/workflow_input.dart';
import '../builder_mixins/platforms_builder_mixin.dart';
import 'project_setup_builder.dart';

class AnalyzeBuilder with PlatformsBuilderMixin implements StepBuilder {
  final WorkflowInput repository;
  final WorkflowInput workingDirectory;
  final WorkflowInput buildRunner;
  final WorkflowInput analyzeImage;
  final WorkflowInput publishExclude;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final StepBuilderFn buildAnalyzeStep;

  AnalyzeBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.analyzeImage,
    required this.publishExclude,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
    required this.buildAnalyzeStep,
  });

  @override
  // TODO: implement supportedPlatforms
  List<String> get supportedPlatforms => throw UnimplementedError();

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        // Step.run(
        //   name: 'Install dart_test_tools',
        //   run: '$pubTool global activate dart_test_tools',
        // ),
        ...buildAnalyzeStep(),
        // Step.run(
        //   name: 'Validate library imports',
        //   run: '$pubTool global run dart_test_tools:import_analyzer -lALL',
        //   workingDirectory: Expression.input(workingDirectoryInput),
        // ),
        Step.run(
          name: 'Validate correct formatting',
          run: '$baseTool format -onone --set-exit-if-changed .',
          workingDirectory: Expression.input(workingDirectory),
        ),
        Step.run(
          name: 'Test publishing configuration',
          run: '''
set -e
if [[ ! -z "${Expression.input(publishExclude)}" ]]; then
  IFS=':'
  for path in "${Expression.input(publishExclude)}"; do
    if [ -e "\$path" ]; then
      git rm "\$path"
    fi
  done
fi
exec $pubTool publish --dry-run
''',
          workingDirectory: Expression.input(workingDirectory),
          shell: 'bash',
        ),
      ];
}
