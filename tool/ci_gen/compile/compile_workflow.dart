import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/inputs.dart';
import '../common/jobs/tag_release_job_builder.dart';
import '../common/outputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/compile_job_builder.dart';

class CompileWorkflow implements WorkflowBuilder {
  const CompileWorkflow();

  @override
  String get name => 'compile';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final outputContext = WorkflowOutputContext();

    final compileJobBuilder = CompileJobBuilder(
      enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      removePubspecOverrides:
          inputContext(WorkflowInputs.removePubspecOverrides),
      archivePrefix: inputContext(WorkflowInputs.archivePrefix),
    );

    final releaseJobBuilder = TagReleaseJobBuilder(
      compileJobIds: {compileJobBuilder.id},
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      persistCredentials: inputContext(WorkflowInputs.persistCredentials),
      binaryArtifactsPattern: '${inputContext(WorkflowInputs.archivePrefix)}-*',
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          outputs: outputContext.createOutputs(),
        ),
      ),
      jobs: {
        compileJobBuilder.id: compileJobBuilder.build(),
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
    );
  }
}
