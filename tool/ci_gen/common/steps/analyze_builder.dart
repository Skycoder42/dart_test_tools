import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'project_setup_builder.dart';
import 'run_publish_builder.dart';

class AnalyzeBuilder implements StepBuilder {
  static const checkPublishStepId = StepId('checkPublish');
  static final checkPublish = checkPublishStepId.output('publish');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression analyzeImage;
  final Expression panaScoreThreshold;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final StepBuilderFn buildAnalyzeStep;

  const AnalyzeBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.analyzeImage,
    required this.panaScoreThreshold,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
    required this.buildAnalyzeStep,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install pana',
          run: '$pubTool global activate pana',
        ),
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        ...buildAnalyzeStep(),
        Step.run(
          name: 'Run custom_lint',
          run: '$runTool custom_lint',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Validate correct formatting',
          run: 'dart format -onone --set-exit-if-changed '
              r"$(git ls-files '*.dart')",
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          id: checkPublishStepId,
          name: 'Check if package is publishable',
          run: '''
set -e
publish_to=\$(cat pubspec.yaml | yq e ".publish_to" -)
if [[ "\$publish_to" == "none" ]]; then
  ${checkPublish.bashSetter('false')}
else
  ${checkPublish.bashSetter('true')}
fi
''',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        ...RunPublishBuilder(
          workingDirectory: workingDirectory,
          pubTool: pubTool,
          publishStepName: 'Test publishing configuration',
          publishArgs: '--dry-run',
          ifExpression:
              checkPublish.expression.eq(const Expression.literal('true')),
        ).build(),
        Step.run(
          name: 'Validate pana score',
          ifExpression:
              checkPublish.expression.eq(const Expression.literal('true')),
          run: '$pubTool global run pana '
              '--exit-code-threshold $panaScoreThreshold .',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
