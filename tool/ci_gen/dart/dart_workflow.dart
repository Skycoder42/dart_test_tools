import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/jobs/validate_coverage_job_builder.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
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

    final analyzeJobBuilder = DartAnalyzeJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      analyzeImage: inputContext(WorkflowInputs.analyzeImage),
      panaScoreThreshold: inputContext(WorkflowInputs.panaScoreThreshold),
    );
    final unitTestBuilder = DartUnitTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
      minCoverage: inputContext(WorkflowInputs.minCoverage),
    );
    final validateCoverageBuilder = ValidateCoverageJobBuilder(
      unitTestJobId: unitTestBuilder.id,
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
      minCoverage: inputContext(WorkflowInputs.minCoverage),
      coverageExclude: inputContext(WorkflowInputs.coverageExclude),
    );
    final integrationTestBuilder = DartIntegrationTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      integrationTestPaths: inputContext(WorkflowInputs.integrationTestPaths),
      integrationTestSetup: inputContext(WorkflowInputs.integrationTestSetup),
      integrationTestEnvVars:
          secretContext(WorkflowSecrets.integrationTestEnvVars),
      integrationTestCacheConfig:
          inputContext(WorkflowInputs.integrationTestCacheConfig),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
        ),
      ),
      jobs: {
        analyzeJobBuilder.id: analyzeJobBuilder.build(),
        unitTestBuilder.id: unitTestBuilder.build(),
        validateCoverageBuilder.id: validateCoverageBuilder.build(),
        integrationTestBuilder.id: integrationTestBuilder.build(),
      },
    );
  }
}
