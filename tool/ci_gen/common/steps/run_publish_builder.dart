import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class RunPublishBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression publishExclude;
  final String pubTool;
  final String publishStepName;
  final String publishArgs;
  final Expression? ifExpression;

  RunPublishBuilder({
    required this.workingDirectory,
    required this.publishExclude,
    required this.pubTool,
    required this.publishStepName,
    required this.publishArgs,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Remove files to not be published',
          ifExpression: publishExclude.ne(Expression.empty) & ifExpression,
          run: '''
set -e
echo '$publishExclude' | jq -cr '.[]' | while read exclude; do
  if [ -e "\$exclude" ]; then
    git rm -rf "\$exclude" || rm -rf "\$exclude"
  fi
done
''',
          shell: 'bash',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: publishStepName,
          ifExpression: ifExpression,
          run: '$pubTool publish $publishArgs',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
