import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/docker_job_builder.dart';

abstract class DockerWorkflow {
  DockerWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final dockerJobBuilder = DockerJobBuilder(
      dockerHubUsername: secretContext(WorkflowSecrets.dockerHubUsername),
      dockerHubToken: secretContext(WorkflowSecrets.dockerHubToken),
      dockerImageName: inputContext(WorkflowInputs.dockerImageName),
      dockerImageTags: inputContext(WorkflowInputs.dockerImageTags),
      dockerPlatforms: inputContext(WorkflowInputs.dockerPlatforms),
      dockerBuildArgs: inputContext(WorkflowInputs.dockerBuildArgs),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        dockerJobBuilder.id: dockerJobBuilder.build(),
      },
    );
  }
}
