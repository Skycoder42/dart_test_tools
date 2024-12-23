import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/jobs/tag_release_job_builder.dart';
import '../common/outputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/compile_job_builder.dart';

class CompileWorkflow implements WorkflowBuilder {
  const CompileWorkflow();

  @override
  String get name => 'compile';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final compileJobBuilder = CompileJobBuilder(
      enabledPlatforms: inputContext(WorkflowInputs.enabledPlatforms),
      config: CompileJobConfig(inputContext, secretContext),
    );

    final releaseJobBuilder = TagReleaseJobBuilder(
      compileJobIds: {compileJobBuilder.id},
      config: TagReleaseJobConfig(
        inputContext,
        secretContext,
        binaryArtifactsPattern:
            '${inputContext(WorkflowInputs.archivePrefix)}-*',
      ),
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    return Workflow(
      jobs: {
        compileJobBuilder.id: compileJobBuilder.build(),
        releaseJobBuilder.id: releaseJobBuilder.build(),
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
