import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class PublishBuilder implements StepBuilder {
  static const toolsStepId = StepId('tools');
  static late final toolsPub = toolsStepId.output('pub');
  static late final toolsPubRun = toolsStepId.output('pubRun');

  final Expression flutter;
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression publishExclude;
  final Expression pubDevCredentials;

  PublishBuilder({
    required this.flutter,
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.publishExclude,
    required this.pubDevCredentials,
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
          pubTool: toolsPub.expression.toString(),
          runTool: toolsPubRun.expression.toString(),
          skipYqInstall: true,
        ).build(),
        Step.run(
          name: 'Prepare pub.dev credentials',
          run: '''
set -e
cache_dir="\${PUB_CACHE:-~/.pub-cache}"
mkdir -p "\$cache_dir"
echo '$pubDevCredentials' > "\$cache_dir/credentials.json"
''',
        ),
        Step.run(
          name: 'Remove ignored files',
          ifExpression: publishExclude.ne(const Expression.literal('')),
          run: '''
set -e
IFS=':'
for path in "$publishExclude"; do
  if [ -e "\$path" ]; then
    git rm "\$path"
  fi
done
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Publish package',
          run: '${toolsPub.expression} publish --force',
          workingDirectory: workingDirectory.toString(),
        ),
        const Step.run(
          name: 'Clean up credentials',
          ifExpression: Expression('always()'),
          run: r'shred -fzvu "${PUB_CACHE:-~/.pub-cache}/credentials.json"',
        ),
      ];
}
