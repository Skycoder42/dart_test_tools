import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_web_job_builder.dart';

class BuildWebWorkflow implements WorkflowBuilder {
  const BuildWebWorkflow();

  @override
  String get name => 'build-web';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final buildMacosJobBuilder = BuildWebJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      buildNumberArgs: inputContext(WorkflowInputs.buildNumberArgs),
      baseHref: inputContext(WorkflowInputs.baseHref),
      dartDefines: secretContext(WorkflowSecrets.dartDefines),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        buildMacosJobBuilder.id: buildMacosJobBuilder.build(),
      },
    );
  }
}
