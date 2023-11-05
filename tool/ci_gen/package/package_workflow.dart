import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/package_job_builder.dart';

abstract base class PackageWorkflow {
  PackageWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    final packageJobBuilder = PackageJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        packageJobBuilder.id: packageJobBuilder.build(),
      },
    );
  }
}
