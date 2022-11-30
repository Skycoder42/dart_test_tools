import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/run_publish_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class PublishBuilder implements StepBuilder {
  static const toolsStepId = StepId('tools');
  static final toolsPub = toolsStepId.output('pub');
  static final toolsPubRun = toolsStepId.output('pubRun');

  final Expression flutter;
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression publishExclude;
  final Expression pubDevCredentials;
  final Expression prePublish;

  PublishBuilder({
    required this.flutter,
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.publishExclude,
    required this.pubDevCredentials,
    required this.prePublish,
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
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          pubTool: toolsPub.expression.toString(),
          runTool: toolsPubRun.expression.toString(),
          skipYqInstall: true,
        ).build(),
        Step.run(
          name: 'Run pre publish script',
          ifExpression: prePublish.ne(Expression.empty),
          run: prePublish.toString(),
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Prepare pub.dev credentials',
          run: '''
set -e
cache_dir="\$XDG_CONFIG_HOME/dart"
mkdir -p "\$cache_dir"
echo '$pubDevCredentials' > "\$cache_dir/pub-credentials.json"
''',
        ),
        ...RunPublishBuilder(
          workingDirectory: workingDirectory,
          publishExclude: publishExclude,
          pubTool: toolsPub.expression.toString(),
          publishStepName: 'Publish package',
          publishArgs: '--force',
        ).build(),
        const Step.run(
          name: 'Clean up credentials',
          ifExpression: Expression('always()'),
          run: r'shred -fzvu "$XDG_CONFIG_HOME/dart/pub-credentials.json"',
        ),
      ];
}
