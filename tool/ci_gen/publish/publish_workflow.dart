import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/publish_job_builder.dart';
import 'builders/release_job_builder.dart';

abstract class PublishWorkflow {
  PublishWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final releaseJobBuilder = ReleaseJobBuilder(
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
    );
    final publishJobBuilder = PublishJobBuilder(
      flutter: inputContext(WorkflowInputs.flutter),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      publish: inputContext(WorkflowInputs.publish),
      publishExclude: inputContext(WorkflowInputs.publishExclude),
      pubDevCredentials: secretContext(WorkflowSecrets.pubDevCredentials),
      releaseUpdate: ReleaseJobBuilder.updateOutput,
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
        publishJobBuilder.id: publishJobBuilder.build(),
      },
    );
  }
}
