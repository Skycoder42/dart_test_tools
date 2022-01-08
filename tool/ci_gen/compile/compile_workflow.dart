import '../common/api/workflow_input.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';

abstract class CompileWorkflow {
  CompileWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {},
    );
  }
}
