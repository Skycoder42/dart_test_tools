import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_linux_job_builder.dart';

class BuildLinuxWorkflow implements WorkflowBuilder {
  const BuildLinuxWorkflow();

  @override
  String get name => 'build-linux';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final buildLinuxJobBuilder = BuildLinuxJobBuilder(
      config: BuildLinuxJobConfig(
        dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
        flatpakPlatformImage: inputContext(WorkflowInputs.flatpakPlatformImage),
        flatpakSdkVersion: inputContext(WorkflowInputs.flatpakSdkVersion),
        bundleName: inputContext(WorkflowInputs.bundleName),
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        removePubspecOverrides:
            inputContext(WorkflowInputs.removePubspecOverrides),
        localResolution: inputContext(WorkflowInputs.localResolution),
        artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
        buildNumberArgs: inputContext(WorkflowInputs.buildNumberArgs),
        manifestPath: inputContext(WorkflowInputs.manifestPath),
        gpgKey: secretContext(WorkflowSecrets.gpgKey(true)),
        gpgKeyId: secretContext(WorkflowSecrets.gpgKeyId(true)),
      ),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        buildLinuxJobBuilder.id: buildLinuxJobBuilder.build(),
      },
    );
  }
}
