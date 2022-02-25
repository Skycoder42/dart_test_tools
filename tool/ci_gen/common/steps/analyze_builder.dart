import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'project_setup_builder.dart';
import 'run_publish_builder.dart';

class AnalyzeBuilder implements StepBuilder {
  static const checkPublishStepId = StepId('checkPublish');
  static late final checkPublish = checkPublishStepId.output('publish');

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
        Step.run(
          name: 'Install dart_test_tools',
          run: '$pubTool global activate dart_test_tools ^3.2.0',
        ),
        ...ProjectSetupBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        ...buildAnalyzeStep(),
        Step.run(
          name: 'Run extended linters',
          run: '$pubTool global run dart_test_tools:lint '
              '-lALL --actions-printer',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Validate correct formatting',
          run: '$baseTool format -onone --set-exit-if-changed .',
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
          publishExclude: publishExclude,
          pubTool: pubTool,
          publishStepName: 'Test publishing configuration',
          publishArgs: '--dry-run',
          ifExpression:
              checkPublish.expression.eq(const Expression.literal('true')),
        ).build(),
      ];
}
