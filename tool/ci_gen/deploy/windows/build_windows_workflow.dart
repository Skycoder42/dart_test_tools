import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
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
      config: BuildWindowsJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {
        buildWindowsJobBuilder.id: buildWindowsJobBuilder.build(),
      },
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
