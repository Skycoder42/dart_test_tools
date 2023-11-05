import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/output.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/release_job_builder.dart';

class ReleaseWorkflow implements WorkflowBuilder {
  const ReleaseWorkflow();

  @override
  String get name => 'release';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final releaseJobBuilder = ReleaseJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      githubToken: secretContext(WorkflowSecrets.githubToken),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: {
            'releaseCreated': Output(
              value: ReleaseJobBuilder.updateOutput,
              description: 'Holds a boolean value string ("true" or "false"), '
                  'indicating whether a release was created or not.',
            ),
            'releaseVersion': Output(
              value: ReleaseJobBuilder.versionOutput,
              description:
                  'Holds the version number of the created release, if the '
                  'releaseCreated output is true. Otherwise, it is not set.',
            ),
          },
        ),
      ),
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
    );
  }
}
