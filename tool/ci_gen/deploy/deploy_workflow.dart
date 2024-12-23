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
import 'android/jobs/deploy_android_job_builder.dart';
import 'linux/jobs/deploy_linux_job_builder.dart';
import 'macos/jobs/deploy_macos_job_builder.dart';
import 'windows/jobs/deploy_windows_job_builder.dart';

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
      config: TagReleaseJobConfig(
        releaseRef: inputContext(WorkflowInputs.releaseRef),
        dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        tagPrefix: inputContext(WorkflowInputs.tagPrefix),
        persistCredentials: inputContext(WorkflowInputs.persistCredentials),
        binaryArtifactsPattern: 'app-deployment-*',
      ),
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    final deployAndroidJobBuilder = DeployAndroidJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      config: DeployAndroidJobConfig(
        enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        googlePlayTrack: inputContext(WorkflowInputs.googlePlayTrack),
        googlePlayReleaseStatus:
            inputContext(WorkflowInputs.googlePlayReleaseStatus),
        googlePlayKey: secretContext(WorkflowSecrets.googlePlayKey),
      ),
    );

    final deployLinuxJobBuilder = DeployLinuxJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      config: DeployLinuxJobConfig(
        enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
        flatpakPlatformImage: inputContext(WorkflowInputs.flatpakPlatformImage),
        gpgKey: secretContext(WorkflowSecrets.gpgKey(false)),
        gpgKeyId: secretContext(WorkflowSecrets.gpgKeyId(false)),
      ),
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

    final deployWindowsJobBuilder = DeployWindowsJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      isDraft: inputContext(WorkflowInputs.isDraft),
      flightId: inputContext(WorkflowInputs.flightId),
      tenantId: secretContext(WorkflowSecrets.tenantId),
      sellerId: secretContext(WorkflowSecrets.sellerId),
      clientId: secretContext(WorkflowSecrets.clientId),
      clientSecret: secretContext(WorkflowSecrets.clientSecret),
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
        deployAndroidJobBuilder.id: deployAndroidJobBuilder.build(),
        deployLinuxJobBuilder.id: deployLinuxJobBuilder.build(),
        deployMacosJobBuilder.id: deployMacosJobBuilder.build(),
        deployWindowsJobBuilder.id: deployWindowsJobBuilder.build(),
      },
    );
  }
}
