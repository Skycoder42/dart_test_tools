import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/deploy_packagecloud_job_builder.dart';

/// Stage 4 (Deployment): uploads the deb packages produced by the `nfpm`
/// workflow to a packagecloud repository, once per configured ubuntu code name.
///
/// The deb artifact is auto-linked to its producer via the convention default
/// of the `artifactPrefix` input. Gate the invocation on a created release with
/// a job-level `if:` in the calling workflow.
class DeployPackagecloudWorkflow implements WorkflowBuilder {
  const DeployPackagecloudWorkflow();

  @override
  String get name => 'deploy-packagecloud';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final deployPackagecloudJobBuilder = DeployPackagecloudJobBuilder(
      config: DeployPackagecloudJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {
        deployPackagecloudJobBuilder.id: deployPackagecloudJobBuilder.build(),
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
