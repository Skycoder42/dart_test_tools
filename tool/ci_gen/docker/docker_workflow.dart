import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/docker_job_builder.dart';

class DockerWorkflow implements WorkflowBuilder {
  const DockerWorkflow();

  @override
  String get name => 'docker';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final dockerJobBuilder = DockerJobBuilder(
      imageName: inputContext(WorkflowInputs.imageName),
      version: inputContext(WorkflowInputs.version),
      extraTags: inputContext(WorkflowInputs.extraTags),
      dockerPlatforms: inputContext(WorkflowInputs.dockerPlatforms),
      dockerBuildArgs: inputContext(WorkflowInputs.dockerBuildArgs),
      dockerHubUsername: secretContext(WorkflowSecrets.dockerHubUsername),
      dockerHubToken: secretContext(WorkflowSecrets.dockerHubToken),
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
