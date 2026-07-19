import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/build_nfpm_job_builder.dart';

class NfpmWorkflow implements WorkflowBuilder {
  const NfpmWorkflow();

  @override
  String get name => 'nfpm';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final buildNfpmJobBuilder = BuildNfpmJobBuilder(
      config: BuildNfpmJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {buildNfpmJobBuilder.id: buildNfpmJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
