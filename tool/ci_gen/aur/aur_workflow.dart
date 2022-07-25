import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/aur_deploy_job_builder.dart';

abstract class AurWorkflow {
  AurWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final aurDeployJobBuilder = AurDeployJobBuilder(
      createAurUpdate: inputContext(WorkflowInputs.createAurUpdate),
      repository: inputContext(WorkflowInputs.repository),
      aurSshPrivateKey: secretContext(WorkflowSecrets.aurSshPrivateKey),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        aurDeployJobBuilder.id: aurDeployJobBuilder.build(),
      },
    );
  }
}
