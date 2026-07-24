import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/deploy_windows_job_builder.dart';

/// Stage 4 (Deployment): publishes the MSIX installer produced by
/// `build-windows` to the Microsoft Store.
///
/// The installer artifact is auto-linked to `build-windows` via the convention
/// default of the `artifactName` input. Gate the invocation on a created
/// release with a job-level `if:` in the calling workflow.
class DeployWindowsWorkflow implements WorkflowBuilder {
  const DeployWindowsWorkflow();

  @override
  String get name => 'deploy-windows';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final deployWindowsJobBuilder = DeployWindowsJobBuilder(
      config: DeployWindowsJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {deployWindowsJobBuilder.id: deployWindowsJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
