import '../../common/api/workflow_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/api/workflow_secret.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../types/on.dart';
import '../../types/workflow.dart';
import '../../types/workflow_call.dart';
import 'jobs/build_macos_job_builder.dart';

class BuildMacosWorkflow implements WorkflowBuilder {
  const BuildMacosWorkflow();

  @override
  String get name => 'build-macos';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final buildMacosJobBuilder = BuildMacosJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      buildNumberArgs: inputContext(WorkflowInputs.buildNumberArgs),
      dmgConfigPath: inputContext(WorkflowInputs.dmgConfigPath),
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
