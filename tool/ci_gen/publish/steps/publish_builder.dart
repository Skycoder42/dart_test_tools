import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/run_publish_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class PublishBuilder implements StepBuilder {
  static const toolsStepId = StepId('tools');
  static final toolsPub = toolsStepId.output('pub');
  static final toolsPubRun = toolsStepId.output('pubRun');

  final Expression flutter;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression prePublish;
  final Expression extraArtifacts;

  PublishBuilder({
    required this.flutter,
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.prePublish,
    required this.extraArtifacts,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          id: toolsStepId,
          name: 'Prepare build tools',
          run: '''
if $flutter; then
  ${toolsPub.bashSetter('flutter pub')}
  ${toolsPubRun.bashSetter('flutter pub run')}
else
  ${toolsPub.bashSetter('dart pub')}
  ${toolsPubRun.bashSetter('dart run')}
fi
''',
        ),
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          releaseMode: true,
          pubTool: toolsPub.expression.toString(),
          runTool: toolsPubRun.expression.toString(),
          skipYqInstall: true,
        ).build(),
        Step.uses(
          name: 'Download additional artifacts',
          ifExpression: extraArtifacts.ne(Expression.empty),
          uses: Tools.actionsDownloadArtifact,
          withArgs: <String, dynamic>{
            for (final key in ['name', 'path']) key: _artifactConfig(key),
          },
        ),
        Step.run(
          name: 'Run pre publish script',
          ifExpression: prePublish.ne(Expression.empty),
          run: prePublish.toString(),
          workingDirectory: workingDirectory.toString(),
        ),
        ...RunPublishBuilder(
          workingDirectory: workingDirectory,
          pubTool: toolsPub.expression.toString(),
          publishStepName: 'Publish package',
          publishArgs: '--force',
        ).build(),
      ];

  String _artifactConfig(String key) => Expression(
        "fromJSON(${extraArtifacts.value})['$key']",
      ).toString();
}
