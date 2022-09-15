import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/builders/validate_coverage_job_builder.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/dart_analyze_job_builder.dart';
import 'builders/dart_integration_test_job_builder.dart';
import 'builders/dart_unit_test_job_builder.dart';

abstract class DartWorkflow {
  DartWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final analyzeJobBuilder = DartAnalyzeJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      analyzeImage: inputContext(WorkflowInputs.analyzeImage),
      publishExclude: inputContext(WorkflowInputs.publishExclude),
      extendedAnalyzerArgs: inputContext(WorkflowInputs.extendedAnalyzerArgs),
    );
    final unitTestBuilder = DartUnitTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
      minCoverage: inputContext(WorkflowInputs.minCoverage),
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );
    final validateCoverageBuilder = ValidateCoverageJobBuilder(
      unitTestJobId: unitTestBuilder.id,
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
      minCoverage: inputContext(WorkflowInputs.minCoverage),
      coverageExclude: inputContext(WorkflowInputs.coverageExclude),
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );
    final integrationTestBuilder = DartIntegrationTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      integrationTestPaths: inputContext(WorkflowInputs.integrationTestPaths),
      integrationTestSetup: inputContext(WorkflowInputs.integrationTestSetup),
      integrationTestEnvVars:
          secretContext(WorkflowSecrets.integrationTestEnvVars),
      platforms: inputContext.builder(WorkflowInputs.platforms),
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
