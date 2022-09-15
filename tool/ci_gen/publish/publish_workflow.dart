import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/output.dart';
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
      releaseUpdate: ReleaseJobBuilder.updateOutput,
      flutter: inputContext(WorkflowInputs.flutter),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      publish: inputContext(WorkflowInputs.publish),
      publishExclude: inputContext(WorkflowInputs.publishExclude),
      prePublish: inputContext(WorkflowInputs.prePublish),
      pubDevCredentials: secretContext(WorkflowSecrets.pubDevCredentials),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: {
            'releaseCreated': Output(
              value: ReleaseJobBuilder.updateOutput,
              description: 'Holds a boolean value string ("true" or "false"), '
                  'indicating whether a release was created or not.',
            ),
          },
        ),
      ),
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
        publishJobBuilder.id: publishJobBuilder.build(),
      },
    );
  }
}
