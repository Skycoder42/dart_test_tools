import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/jobs/tag_release_job_builder.dart';
import '../common/outputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'linux/jobs/deploy_linux_job_builder.dart';
import 'macos/jobs/deploy_macos_job_builder.dart';

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
      binaryArtifactsPattern: 'app-deployment-*',
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    final deployLinuxJobBuilder = DeployLinuxJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
      sdkVersion: inputContext(WorkflowInputs.flatpakSdkVersion),
      gpgKey: secretContext(WorkflowSecrets.gpgKey(false)),
      gpgKeyId: secretContext(WorkflowSecrets.gpgKeyId(false)),
    );

    final deployMacosJobBuilder = DeployMacosJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      releaseVersion: releaseJobBuilder.versionOutput,
      enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      targetRepo: inputContext(WorkflowInputs.targetRepo),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      targetRepoToken: secretContext(WorkflowSecrets.targetRepoToken),
    );

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
        deployLinuxJobBuilder.id: deployLinuxJobBuilder.build(),
        deployMacosJobBuilder.id: deployMacosJobBuilder.build(),
      },
    );
  }
}
