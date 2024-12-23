import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/jobs/validate_coverage_job_builder.dart';
import '../common/outputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/dart_analyze_job_builder.dart';
import 'jobs/dart_integration_test_job_builder.dart';
import 'jobs/dart_unit_test_job_builder.dart';

class DartWorkflow implements WorkflowBuilder {
  const DartWorkflow();

  @override
  String get name => 'dart';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final analyzeJobBuilder = DartAnalyzeJobBuilder(
      config: DartAnalyzeJobConfig(
        inputContext,
        secretContext,
      ),
    );
    outputContext.add(
      WorkflowOutputs.enabledPlatforms,
      analyzeJobBuilder.platformsOutput,
    );

    final unitTestBuilder = DartUnitTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: DartUnitTestJobConfig(
        inputContext,
        secretContext,
      ),
    );

    final validateCoverageBuilder = ValidateCoverageJobBuilder(
      unitTestJobId: unitTestBuilder.id,
      config: ValidateCoverageJobConfig(
        inputContext,
        secretContext,
      ),
    );

    final integrationTestBuilder = DartIntegrationTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: DartIntegrationTestJobConfig(
        inputContext,
        secretContext,
      ),
    );

    return Workflow(
      jobs: {
        analyzeJobBuilder.id: analyzeJobBuilder.build(),
        unitTestBuilder.id: unitTestBuilder.build(),
        validateCoverageBuilder.id: validateCoverageBuilder.build(),
        integrationTestBuilder.id: integrationTestBuilder.build(),
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
