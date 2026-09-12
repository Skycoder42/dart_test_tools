import 'dart:convert';

import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

base mixin TriggerDeployConfig on JobConfig {
  late final publishWorkflow = inputContext(WorkflowInputs.publishWorkflow);
  late final tagPrefix = inputContext(WorkflowInputs.tagPrefix);
}

class TriggerDeployBuilder({
  required final TriggerDeployConfig config,
  required final Expression versionUpdate,
  required final Expression versionOutput,
}) implements StepBuilder {
  @override
  Iterable<Step> build() => [
    Step.uses(
      name: 'Trigger deployment',
      uses: Tools.bencUkWorkflowDispatch,
      ifExpression: versionUpdate.eq(const Expression.literal('true')),
      withArgs: {
        'workflow': config.publishWorkflow.toString(),
        'ref': 'refs/tags/${config.tagPrefix}$versionOutput',
        'inputs': json.encode({'version': versionOutput.toString()}),
      },
    ),
  ];
}
