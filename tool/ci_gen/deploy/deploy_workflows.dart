import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/jobs/tag_release_job_builder.dart';
import '../common/outputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/build_android_job_builder.dart';

class DeployWorkflow implements WorkflowBuilder {
  const DeployWorkflow();

  @override
  String get name => 'deploy';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final buildAppJobBuilder = BuildAndroidJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
    );

    final releaseJobBuilder = TagReleaseJobBuilder(
      compileJobId: buildAppJobBuilder.id,
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      persistCredentials: inputContext(WorkflowInputs.persistCredentials),
      // binaryArtifactsPattern: 'apps-*',
      binaryArtifactsPattern: null,
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: outputContext.createOutputs(),
        ),
      ),
      jobs: {
        buildAppJobBuilder.id: buildAppJobBuilder.build(),
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
    );
  }
}
