import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'project_setup_builder.dart';
import 'run_publish_builder.dart';

class AnalyzeBuilder implements StepBuilder {
  static const checkPublishStepId = StepId('checkPublish');
  static final checkPublishOutput = checkPublishStepId.output('publish');

  static const checkPlatformsStepId = StepId('checkPlatforms');
  static final platformsOutput = checkPlatformsStepId.output('platforms');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression analyzeImage;
  final Expression panaScoreThreshold;
  final bool isFlutter;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final StepBuilderFn buildAnalyzeStep;

  const AnalyzeBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.analyzeImage,
    required this.panaScoreThreshold,
    required this.isFlutter,
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
          removePubspecOverrides: removePubspecOverrides,
          isFlutter: ExpressionOrValue.value(isFlutter),
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          id: checkPlatformsStepId,
          name: 'Check supported platforms',
          run: '''
set -eo pipefail
platforms=\$(yq '.platforms // {} | keys' -o=json -I=0 pubspec.yaml)
echo "Detected supported platforms as: \$platforms"
${platformsOutput.bashSetter(r'$platforms')}
''',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
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
set -eo pipefail
publish_to=\$(cat pubspec.yaml | yq e ".publish_to" -)
if [[ "\$publish_to" == "none" ]]; then
  ${checkPublishOutput.bashSetter('false')}
else
  ${checkPublishOutput.bashSetter('true')}
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
          ifExpression: checkPublishOutput.expression
              .eq(const Expression.literal('true')),
        ).build(),
        Step.run(
          name: 'Validate pana score',
          ifExpression: checkPublishOutput.expression
              .eq(const Expression.literal('true')),
          run: '$pubTool global run pana '
              '--exit-code-threshold $panaScoreThreshold .',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
