import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../api/workflow_input.dart';
import 'checkout_builder.dart';

class ProjectSetupBuilder implements StepBuilder {
  final WorkflowInput repository;
  final WorkflowInput workingDirectory;
  final WorkflowInput buildRunner;
  final String pubTool;
  final String runTool;

  const ProjectSetupBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Install yq (Windows)',
          ifExpression: "runner.os == 'Windows'",
          run: 'choco install yq',
        ),
        const Step.run(
          name: 'Install yq (macOS)',
          ifExpression: "runner.os == 'macOS'",
          run: 'brew install yq',
        ),
        ...CheckoutBuilder(repository: repository).build(),
        Step.run(
          name: 'Remove dependency overrides',
          run: 'yq e -i "del(.dependency_overrides)" pubspec.yaml',
          workingDirectory: Expression.input(workingDirectory),
        ),
        Step.run(
          name: 'Restore dart packages',
          run: '$pubTool get',
          workingDirectory: Expression.input(workingDirectory),
        ),
        Step.run(
          name: 'Create build files',
          ifExpression: buildRunner.expression,
          run: '$runTool build_runner build',
          workingDirectory: Expression.input(workingDirectory),
        ),
      ];
}
