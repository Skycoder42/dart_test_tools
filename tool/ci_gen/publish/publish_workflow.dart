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
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
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
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      publish: inputContext(WorkflowInputs.publish),
      prePublish: inputContext(WorkflowInputs.prePublish),
      extraArtifacts: inputContext(WorkflowInputs.extraArtifacts),
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
            'releaseVersion': Output(
              value: ReleaseJobBuilder.versionOutput,
              description:
                  'Holds the version number of the created release, if the '
                  'releaseCreated output is true. Otherwise, it is not set.',
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
