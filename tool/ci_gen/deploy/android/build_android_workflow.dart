import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_output.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/outputs.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_android_job_builder.dart';

class BuildAndroidWorkflow implements WorkflowBuilder {
  const BuildAndroidWorkflow();

  @override
  String get name => 'build-android';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final buildAndroidJobBuilder = BuildAndroidJobBuilder(
      config: BuildAndroidJobConfig(inputContext, secretContext),
    );
    outputContext.add(
      WorkflowOutputs.artifactName,
      buildAndroidJobBuilder.artifactNameOutput,
    );

    return Workflow(
      jobs: {buildAndroidJobBuilder.id: buildAndroidJobBuilder.build()},
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
