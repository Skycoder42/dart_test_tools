import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class ProjectPrepareBuilder implements StepBuilder {
  final String? titleSuffix;
  final Expression workingDirectory;
  final Expression releaseRef;
  final Expression? buildRunner;
  final String pubTool;
  final String runTool;
  final Expression? ifExpression;

  const ProjectPrepareBuilder({
    this.titleSuffix,
    required this.workingDirectory,
    required this.releaseRef,
    this.buildRunner,
    required this.pubTool,
    required this.runTool,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Remove pubspec_overrides.yaml$_titleSuffix',
          ifExpression: Expression.parens(
                releaseRef.not | const Expression('github.ref').eq(releaseRef),
              ) &
              ifExpression,
          run: 'find . -type f -name "pubspec_overrides.yaml" '
              r'-exec git rm -f {} \;',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
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
