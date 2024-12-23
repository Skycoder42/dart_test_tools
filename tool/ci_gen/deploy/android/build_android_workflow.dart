import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_android_job_builder.dart';

class BuildAndroidWorkflow implements WorkflowBuilder {
  const BuildAndroidWorkflow();

  @override
  String get name => 'build-android';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final buildAndroidJobBuilder = BuildAndroidJobBuilder(
      config: BuildAndroidJobConfig(
        flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
        javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        removePubspecOverrides:
            inputContext(WorkflowInputs.removePubspecOverrides),
        localResolution: inputContext(WorkflowInputs.localResolution),
        artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
        buildRunner: inputContext(WorkflowInputs.buildRunner),
        buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
        buildNumberArgs: inputContext(WorkflowInputs.buildNumberArgs),
        primaryLocale: inputContext(WorkflowInputs.primaryLocale),
        dartDefines: secretContext(WorkflowSecrets.dartDefines),
        keystore: secretContext(WorkflowSecrets.keystore),
        keystorePassword: secretContext(WorkflowSecrets.keystorePassword),
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
        buildAndroidJobBuilder.id: buildAndroidJobBuilder.build(),
      },
    );
  }
}
