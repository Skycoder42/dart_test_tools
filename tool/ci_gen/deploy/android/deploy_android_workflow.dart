import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/deploy_android_job_builder.dart';

/// Stage 4 (Deployment): deploys the android app bundle produced by
/// `build-android` to Google Play.
///
/// The bundle artifact is auto-linked to `build-android` via the convention
/// default of the `artifactName` input. Gate the invocation on a created
/// release with a job-level `if:` in the calling workflow.
class DeployAndroidWorkflow implements WorkflowBuilder {
  const DeployAndroidWorkflow();

  @override
  String get name => 'deploy-android';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final deployAndroidJobBuilder = DeployAndroidJobBuilder(
      config: DeployAndroidJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {deployAndroidJobBuilder.id: deployAndroidJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
