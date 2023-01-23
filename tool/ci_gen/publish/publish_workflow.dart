import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/create_release_job_builder.dart';
import 'jobs/publish_job_builder.dart';
import 'jobs/release_job_builder.dart';

abstract class PublishWorkflow {
  PublishWorkflow._();

  static Workflow buildPublishWorkflow() {
    final inputContext = WorkflowInputContext();

    final releaseJobBuilder = ReleaseJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      releaseRef: inputContext(WorkflowInputs.releaseRef),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        releaseJobBuilder.id: releaseJobBuilder.build(),
      },
    );
  }

  static Workflow buildCreateReleaseWorkflow() {
    final inputContext = WorkflowInputContext();

    final createReleaseJobBuilder = CreateReleaseJobBuilder(
      clientPayload: inputContext(WorkflowInputs.clientPayload),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        createReleaseJobBuilder.id: createReleaseJobBuilder.build(),
      },
    );
  }

  static Workflow buildPubPublishWorkflow() {
    final inputContext = WorkflowInputContext();

    final publishJobBuilder = PublishJobBuilder(
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
      flutter: inputContext(WorkflowInputs.flutter),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      prePublish: inputContext(WorkflowInputs.prePublish),
      extraArtifacts: inputContext(WorkflowInputs.extraArtifacts),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        publishJobBuilder.id: publishJobBuilder.build(),
      },
    );
  }
}
