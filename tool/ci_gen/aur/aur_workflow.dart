import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
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
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final aurDeployJobBuilder = AurDeployJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
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
