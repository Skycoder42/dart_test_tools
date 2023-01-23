import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class RunPublishBuilder implements StepBuilder {
  final Expression workingDirectory;
  final String pubTool;
  final String publishStepName;
  final String publishArgs;
  final Expression? ifExpression;

  RunPublishBuilder({
    required this.workingDirectory,
    required this.pubTool,
    required this.publishStepName,
    required this.publishArgs,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: publishStepName,
          ifExpression: ifExpression,
          run: '$pubTool publish $publishArgs',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
