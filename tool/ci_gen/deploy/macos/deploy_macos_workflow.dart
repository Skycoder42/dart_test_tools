import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/deploy_macos_job_builder.dart';

/// Stage 4 (Deployment): publishes a homebrew cask for the DMG image built by
/// `build-macos` (and attached to the release) to a homebrew tap.
///
/// The cask references the release assets by version, so this workflow consumes
/// only the `version` input (the released version) rather than a build
/// artifact. Gate the invocation on a created release with a job-level `if:` in
/// the calling workflow.
class DeployMacosWorkflow implements WorkflowBuilder {
  const DeployMacosWorkflow();

  @override
  String get name => 'deploy-macos';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final deployMacosJobBuilder = DeployMacosJobBuilder(
      config: DeployMacosJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {deployMacosJobBuilder.id: deployMacosJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
