import '../types/expression.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/docker_job_builder.dart';

abstract class DockerWorkflow {
  DockerWorkflow._();

  static Workflow buildWorkflow() {
    final dockerJobBuilder = DockerJobBuilder(
      repository: const Expression('repository'),
      dockerHubUsername: const Expression('dockerHubUsername'),
      dockerHubToken: const Expression('dockerHubToken'),
      dockerPlatforms: const Expression('dockerPlatforms'),
      dockerBuildArgs: const Expression('dockerBuildArgs'),
    );

    return Workflow(
      on: const On(
        workflowCall: WorkflowCall(),
      ),
      jobs: {
        dockerJobBuilder.id: dockerJobBuilder.build(),
      },
    );
  }
}
