import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/release_job_builder.dart';

abstract class PublishWorkflow {
  PublishWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    final releaseJobBuilder = ReleaseJobBuilder(
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        releaseJobBuilder.name: releaseJobBuilder.build(),
      },
    );
  }
}
