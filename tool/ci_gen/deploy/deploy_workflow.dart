import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/jobs/tag_release_job_builder.dart';
import '../common/outputs.dart';
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
        inputContext,
        secretContext,
        binaryArtifactsPattern: 'app-deployment-*',
      ),
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    final deployAndroidJobBuilder = DeployAndroidJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      config: DeployAndroidJobConfig(inputContext, secretContext),
    );

    final deployLinuxJobBuilder = DeployLinuxJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      config: DeployLinuxJobConfig(inputContext, secretContext),
    );

    final deployMacosJobBuilder = DeployMacosJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      releaseVersion: releaseJobBuilder.versionOutput,
      config: DeployMacosJobConfig(inputContext, secretContext),
    );

    final deployWindowsJobBuilder = DeployWindowsJobBuilder(
      releaseCreated: releaseJobBuilder.updateOutput,
      config: DeployWindowsJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
        deployAndroidJobBuilder.id: deployAndroidJobBuilder.build(),
        deployLinuxJobBuilder.id: deployLinuxJobBuilder.build(),
        deployMacosJobBuilder.id: deployMacosJobBuilder.build(),
        deployWindowsJobBuilder.id: deployWindowsJobBuilder.build(),
      },
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: outputContext.createOutputs(),
        ),
      ),
    );
  }
}
