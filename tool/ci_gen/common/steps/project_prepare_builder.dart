import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class ProjectPrepareBuilder implements StepBuilder {
  final String? titleSuffix;
  final Expression workingDirectory;
  final Expression? buildRunner;
  final String pubTool;
  final String runTool;
  final Expression? ifExpression;

  const ProjectPrepareBuilder({
    this.titleSuffix,
    required this.workingDirectory,
    this.buildRunner,
    required this.pubTool,
    required this.runTool,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Remove dependency overrides$_titleSuffix',
          ifExpression: ifExpression,
          run: 'yq e -i "del(.dependency_overrides)" pubspec.yaml',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Restore dart packages$_titleSuffix',
          ifExpression: ifExpression,
          run: '$pubTool get',
          workingDirectory: workingDirectory.toString(),
        ),
        if (buildRunner != null)
          Step.run(
            name: 'Create build files$_titleSuffix',
            ifExpression: buildRunner! & ifExpression,
            run: '$runTool build_runner build',
            workingDirectory: workingDirectory.toString(),
          ),
      ];

  String get _titleSuffix => titleSuffix != null ? ' $titleSuffix' : '';
}
