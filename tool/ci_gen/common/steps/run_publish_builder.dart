import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class RunPublishBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression publishExclude;
  final String pubTool;
  final String publishStepName;
  final String publishArgs;

  RunPublishBuilder({
    required this.workingDirectory,
    required this.publishExclude,
    required this.pubTool,
    required this.publishStepName,
    required this.publishArgs,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Remove files to not be published',
          ifExpression: publishExclude.ne(const Expression.literal('')),
          run: '''
set -e
echo '$publishExclude' | jq -c '.[]' | while read exclude; do
  if [ -e "\$exclude" ]; then
    git rm "\$exclude"
  fi
done
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: publishStepName,
          run: '$pubTool publish $publishArgs',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
