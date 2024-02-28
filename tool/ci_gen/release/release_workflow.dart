import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/outputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
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
    final outputContext = WorkflowOutputContext();

    final releaseJobBuilder = ReleaseJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      githubToken: secretContext(WorkflowSecrets.githubToken),
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: outputContext.createOutputs(),
        ),
      ),
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
    );
  }
}
