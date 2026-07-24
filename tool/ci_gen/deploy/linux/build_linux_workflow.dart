import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_output.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/outputs.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_linux_job_builder.dart';

class BuildLinuxWorkflow implements WorkflowBuilder {
  const BuildLinuxWorkflow();

  @override
  String get name => 'build-linux';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final buildLinuxJobBuilder = BuildLinuxJobBuilder(
      config: BuildLinuxJobConfig(inputContext, secretContext),
    );
    outputContext.add(
      WorkflowOutputs.artifactName,
      buildLinuxJobBuilder.artifactNameOutput,
    );

    return Workflow(
      jobs: {buildLinuxJobBuilder.id: buildLinuxJobBuilder.build()},
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
