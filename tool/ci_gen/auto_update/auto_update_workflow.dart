import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/auto_update_job_builder.dart';
import 'jobs/check_update_required_job_builder.dart';

class AutoUpdateWorkflow implements WorkflowBuilder {
  const AutoUpdateWorkflow();

  @override
  String get name => 'auto-update';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final checkUpdateRequiredJobBuilder = CheckUpdateRequiredJobBuilder(
      config: CheckUpdateRequiredJobConfig(inputContext, secretContext),
    );

    final autoUpdateJobBuilder = AutoUpdateJobBuilder(
      hasOutdated: checkUpdateRequiredJobBuilder.hasOutdated,
      hasSecurityIssues: checkUpdateRequiredJobBuilder.hasSecurityIssues,
      config: AutoUpdateJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {
        checkUpdateRequiredJobBuilder.id: checkUpdateRequiredJobBuilder.build(),
        autoUpdateJobBuilder.id: autoUpdateJobBuilder.build(),
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
