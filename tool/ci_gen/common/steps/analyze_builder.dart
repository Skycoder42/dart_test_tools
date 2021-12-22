import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'project_setup_builder.dart';
import 'run_publish_builder.dart';

class AnalyzeBuilder implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression analyzeImage;
  final Expression publishExclude;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final StepBuilderFn buildAnalyzeStep;

  const AnalyzeBuilder({
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
          workingDirectory: workingDirectory.toString(),
        ),
        ...RunPublishBuilder(
          workingDirectory: workingDirectory,
          publishExclude: publishExclude,
          pubTool: pubTool,
          publishStepName: 'Test publishing configuration',
          publishArgs: '--dry-run',
        ).build(),
      ];
}
