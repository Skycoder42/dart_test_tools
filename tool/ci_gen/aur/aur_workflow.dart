import '../common/api/workflow_builder.dart';
import '../common/api/workflow_secret.dart';
import '../common/secrets.dart';
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
