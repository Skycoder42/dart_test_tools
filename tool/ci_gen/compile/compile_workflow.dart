import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/output.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/compile_job_builder.dart';
import 'jobs/release_job_builder.dart';

abstract class CompileWorkflow {
  CompileWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    final compileJobBuilder = CompileJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      platforms: inputContext.builder(WorkflowInputs.platforms),
      targets: inputContext(WorkflowInputs.targets),
    );

    final releaseJobBuilder = ReleaseJobBuilder(
      compileJobId: compileJobBuilder.id,
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      persistCredentials: inputContext(WorkflowInputs.persistCredentials),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          outputs: {
            'releaseCreated': Output(
              value: ReleaseJobBuilder.updateOutput,
              description: 'Holds a boolean value string ("true" or "false"), '
                  'indicating whether a release was created or not.',
            ),
            'releaseVersion': Output(
              value: ReleaseJobBuilder.versionOutput,
              description:
                  'Holds the version number of the created release, if the '
                  'releaseCreated output is true. Otherwise, it is not set.',
            ),
          },
        ),
      ),
      jobs: {
        compileJobBuilder.id: compileJobBuilder.build(),
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
    );
  }
}
