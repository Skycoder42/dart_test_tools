import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_output.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/outputs.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_macos_job_builder.dart';

class BuildMacosWorkflow implements WorkflowBuilder {
  const BuildMacosWorkflow();

  @override
  String get name => 'build-macos';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final buildMacosJobBuilder = BuildMacosJobBuilder(
      config: BuildMacosJobConfig(inputContext, secretContext),
    );
    outputContext.add(
      WorkflowOutputs.artifactName,
      buildMacosJobBuilder.artifactNameOutput,
    );

    return Workflow(
      jobs: {buildMacosJobBuilder.id: buildMacosJobBuilder.build()},
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
