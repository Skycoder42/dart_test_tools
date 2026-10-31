import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/renovate_finish_job_builder.dart';

class const RenovateFinishWorkflow() implements WorkflowBuilder {
  @override
  String get name => 'renovate-finish';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final finishJobBuilder = RenovateFinishJobBuilder(
      config: RenovateFinishJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {finishJobBuilder.id: finishJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
