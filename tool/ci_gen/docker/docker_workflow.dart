import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
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
      config: DockerJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {dockerJobBuilder.id: dockerJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
