import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/aur_deploy_job_builder.dart';

class AurWorkflow implements WorkflowBuilder {
  const AurWorkflow();

  @override
  String get name => 'aur';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final aurDeployJobBuilder = AurDeployJobBuilder(
      config: AurDeployJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {
        aurDeployJobBuilder.id: aurDeployJobBuilder.build(),
      },
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
