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

class DeployWorkflow implements WorkflowBuilder {
  const DeployWorkflow();

  @override
  String get name => 'deploy';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final releaseJobBuilder = TagReleaseJobBuilder(
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      persistCredentials: inputContext(WorkflowInputs.persistCredentials),
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    // final deployAndroidJobBuilder = DeployAndroidJobBuilder(
    //   enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
    //   releaseCreated: releaseJobBuilder.updateOutput,
    //   flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
    //   javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
    //   workingDirectory: inputContext(WorkflowInputs.workingDirectory),
    //   buildNumber: buildAndroidJobBuilder.buildNumber,
    //   googlePlayTrack: inputContext(WorkflowInputs.googlePlayTrack),
    //   googlePlayReleaseStatus:
    //       inputContext(WorkflowInputs.googlePlayReleaseStatus),
    //   sentryAuthToken: secretContext(WorkflowSecrets.sentryAuthToken),
    //   googlePlayKey: secretContext(WorkflowSecrets.googlePlayKey),
    // );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: outputContext.createOutputs(),
        ),
      ),
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
        // deployAndroidJobBuilder.id: deployAndroidJobBuilder.build(),
      },
    );
  }
}
