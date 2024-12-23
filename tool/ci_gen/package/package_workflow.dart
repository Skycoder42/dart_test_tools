import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/package_job_builder.dart';

class PackageWorkflow implements WorkflowBuilder {
  const PackageWorkflow();

  @override
  String get name => 'package';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final packageJobBuilder = PackageJobBuilder(
      config: PackageJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {
        packageJobBuilder.id: packageJobBuilder.build(),
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
