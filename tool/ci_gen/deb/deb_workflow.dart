import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/deb_deploy_job_builder.dart';

class DebWorkflow implements WorkflowBuilder {
  const DebWorkflow();

  @override
  String get name => 'deb';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();

    final debDeployJobBuilder = DebDeployJobBuilder(
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      version: inputContext(WorkflowInputs.version),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        debDeployJobBuilder.id: debDeployJobBuilder.build(),
      },
    );
  }
}
