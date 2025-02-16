import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_web_job_builder.dart';

class BuildWebWorkflow implements WorkflowBuilder {
  const BuildWebWorkflow();

  @override
  String get name => 'build-web';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final buildMacosJobBuilder = BuildWebJobBuilder(
      config: BuildWebJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {buildMacosJobBuilder.id: buildMacosJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
    );
  }
}
