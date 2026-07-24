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

/// Stage 3 (Release-Check): checks whether the current package version has
/// already been released as a git tag and, if not, creates a GitHub release and
/// attaches all "orphan" build artifacts (those without a dedicated deployment
/// target) matched by [WorkflowInputs.binaryArtifactsPattern].
///
/// Meant to be called after the stage-2 build/bundle workflows (via `needs`),
/// so the artifacts they uploaded are available for download in the same run.
class CreateReleaseWorkflow implements WorkflowBuilder {
  const CreateReleaseWorkflow();

  @override
  String get name => 'create-release';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final releaseJobBuilder = TagReleaseJobBuilder(
      config: TagReleaseJobConfig(inputContext, secretContext),
    );
    outputContext
      ..add(WorkflowOutputs.releaseCreated, releaseJobBuilder.updateOutput)
      ..add(WorkflowOutputs.releaseVersion, releaseJobBuilder.versionOutput);

    return Workflow(
      jobs: {releaseJobBuilder.id: releaseJobBuilder.build()},
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
