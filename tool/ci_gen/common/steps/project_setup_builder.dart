import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'checkout_builder.dart';

class ProjectSetupBuilder implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final String pubTool;
  final String runTool;
  final Expression? ifExpression;

  const ProjectSetupBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.pubTool,
    required this.runTool,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install yq (Windows)',
          ifExpression:
              const Expression("runner.os == 'Windows'") & ifExpression,
          run: 'choco install yq',
        ),
        Step.run(
          name: 'Install yq (macOS)',
          ifExpression: const Expression("runner.os == 'macOS'") & ifExpression,
          run: 'brew install yq',
        ),
        ...CheckoutBuilder(
          repository: repository,
          ifExpression: ifExpression,
        ).build(),
        Step.run(
          name: 'Remove dependency overrides',
          ifExpression: ifExpression,
          run: 'yq e -i "del(.dependency_overrides)" pubspec.yaml',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Restore dart packages',
          ifExpression: ifExpression,
          run: '$pubTool get',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Create build files',
          ifExpression: buildRunner & ifExpression,
          run: '$runTool build_runner build',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
