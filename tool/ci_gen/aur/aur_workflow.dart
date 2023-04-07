import '../common/api/workflow_secret.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/aur_deploy_job_builder.dart';

abstract class AurWorkflow {
  AurWorkflow._();

  static Workflow buildWorkflow() {
    final secretContext = WorkflowSecretContext();

    final aurDeployJobBuilder = AurDeployJobBuilder(
      aurSshPrivateKey: secretContext(WorkflowSecrets.aurSshPrivateKey),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        aurDeployJobBuilder.id: aurDeployJobBuilder.build(),
      },
    );
  }
}
