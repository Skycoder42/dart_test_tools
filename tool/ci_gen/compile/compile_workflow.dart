import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/outputs.dart';
import '../types/env.dart';
import '../types/expression.dart';
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
    outputContext.add(
      WorkflowOutputs.artifactName,
      compileJobBuilder.artifactNameOutput,
    );

    final env = inputContext(WorkflowInputs.env);

    return Workflow(
      jobs: {compileJobBuilder.id: compileJobBuilder.build()},
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
          outputs: outputContext.createOutputs(),
        ),
      ),
      env: Env.expression(const Expression('fromJSON')([env])),
    );
  }
}
