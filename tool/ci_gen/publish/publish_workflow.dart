import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../types/env.dart';
import '../types/expression.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/publish_job_builder.dart';

class PublishWorkflow implements WorkflowBuilder {
  const PublishWorkflow();

  @override
  String get name => 'publish';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final publishJobBuilder = PublishJobBuilder(
      config: PublishJobConfig(inputContext, secretContext),
    );

    final env = inputContext(WorkflowInputs.env);

    return Workflow(
      jobs: {publishJobBuilder.id: publishJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      env: Env.expression(const Expression('fromJSON')([env])),
    );
  }
}
