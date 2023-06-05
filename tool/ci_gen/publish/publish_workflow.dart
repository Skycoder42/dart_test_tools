import '../common/api/workflow_input.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/publish_job_builder.dart';

abstract class PublishWorkflow {
  PublishWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    final publishJobBuilder = PublishJobBuilder(
      flutter: inputContext(WorkflowInputs.flutter),
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      environment: inputContext(WorkflowInputs.environment),
      tagPrefix: inputContext(WorkflowInputs.tagPrefix),
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
