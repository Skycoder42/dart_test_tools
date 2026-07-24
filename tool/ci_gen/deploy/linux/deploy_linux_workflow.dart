import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/deploy_linux_job_builder.dart';

/// Stage 4 (Deployment): imports the flatpak bundles produced by `build-linux`
/// into the flatpak repository published via GitHub Pages.
///
/// The bundle artifacts are auto-linked to `build-linux` via the convention
/// default of the `artifactPattern` input. Gate the invocation on a created
/// release with a job-level `if:` in the calling workflow.
class DeployLinuxWorkflow implements WorkflowBuilder {
  const DeployLinuxWorkflow();

  @override
  String get name => 'deploy-linux';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final deployLinuxJobBuilder = DeployLinuxJobBuilder(
      config: DeployLinuxJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {deployLinuxJobBuilder.id: deployLinuxJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
