import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/deb_deploy_job_builder.dart';
import 'jobs/packagecloud_upload_job_builder.dart';

class DebWorkflow implements WorkflowBuilder {
  const DebWorkflow();

  @override
  String get name => 'deb';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final debDeployJobBuilder = DebDeployJobBuilder(
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
    );

    final packagecloudUploadJobBuilder = PackagecloudUploadJobBuilder(
      packageJobId: debDeployJobBuilder.id,
      repository: inputContext(WorkflowInputs.packagecloudRepository),
      packagecloudToken: secretContext(WorkflowSecrets.packagecloudToken),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        debDeployJobBuilder.id: debDeployJobBuilder.build(),
        packagecloudUploadJobBuilder.id: packagecloudUploadJobBuilder.build(),
      },
    );
  }
}
