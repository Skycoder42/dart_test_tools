import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/compile_job_builder.dart';
import 'builders/release_job_builder.dart';

abstract class CompileWorkflow {
  CompileWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    final compileJobBuilder = CompileJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      platforms: inputContext.builder(WorkflowInputs.platforms),
      targets: inputContext(WorkflowInputs.targets),
    );

    final releaseJobBuilder = ReleaseJobBuilder(
      compileJobId: compileJobBuilder.id,
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        compileJobBuilder.id: compileJobBuilder.build(),
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
    );
  }
}
