import '../common/api/workflow_input.dart';
import '../common/builders/validate_coverage_job_builder.dart';
import '../common/inputs.dart';
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

    final analyzeJobBuilder = DartAnalyzeJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      analyzeImage: inputContext(WorkflowInputs.analyzeImage),
      publishExclude: inputContext(WorkflowInputs.publishExclude),
    );
    final unitTestBulder = DartUnitTestJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
      minCoverage: inputContext(WorkflowInputs.minCoverage),
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );
    final validateCoverageBuilder = ValidateCoverageJobBuilder(
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
      minCoverage: inputContext(WorkflowInputs.minCoverage),
      coverageExclude: inputContext(WorkflowInputs.coverageExclude),
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );
    final integrationTestBuilder = DartIntegrationTestJobBuilder(
      dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      integrationTestPaths: inputContext(WorkflowInputs.integrationTestPaths),
      integrationTestSetup: inputContext(WorkflowInputs.integrationTestSetup),
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
        ),
      ),
      jobs: {
        analyzeJobBuilder.name: analyzeJobBuilder.build(),
        unitTestBulder.name: unitTestBulder.build([analyzeJobBuilder]),
        validateCoverageBuilder.name:
            validateCoverageBuilder.build([unitTestBulder]),
        integrationTestBuilder.name:
            integrationTestBuilder.build([analyzeJobBuilder]),
      },
    );
  }
}
