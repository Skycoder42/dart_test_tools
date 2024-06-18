import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_windows_job_builder.dart';

class BuildWindowsWorkflow implements WorkflowBuilder {
  const BuildWindowsWorkflow();

  @override
  String get name => 'build-windows';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final buildWindowsJobBuilder = BuildWindowsJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      removePubspecOverrides:
          inputContext(WorkflowInputs.removePubspecOverrides),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      buildNumberArgs: inputContext(WorkflowInputs.buildNumberArgs),
      dartDefines: secretContext(WorkflowSecrets.dartDefines),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        buildWindowsJobBuilder.id: buildWindowsJobBuilder.build(),
      },
    );
  }
}
