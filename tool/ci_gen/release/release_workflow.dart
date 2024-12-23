import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/outputs.dart';
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
      config: ReleaseJobConfig(inputContext, secretContext),
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    return Workflow(
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: outputContext.createOutputs(),
        ),
      ),
    );
  }
}
