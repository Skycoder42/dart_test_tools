import '../common/api/workflow_input.dart';
import '../common/builders/validate_coverage_job_builder.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/flutter_analyze_job_builder.dart';
import 'builders/flutter_integration_test_job_builder.dart';
import 'builders/flutter_unit_test_job_builder.dart';

abstract class FlutterWorkflow {
  FlutterWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    final analyzeJobBuilder = FlutterAnalyzeJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      analyzeImage: inputContext(WorkflowInputs.analyzeImage),
      publishExclude: inputContext(WorkflowInputs.publishExclude),
    );
    final unitTestBuilder = FlutterUnitTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
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
    final integrationTestBuilder = FlutterIntegrationTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      repository: inputContext(WorkflowInputs.repository),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      integrationTestSetup: inputContext(WorkflowInputs.integrationTestSetup),
      integrationTestPaths: inputContext(WorkflowInputs.integrationTestPaths),
      integrationTestProject:
          inputContext(WorkflowInputs.integrationTestProject),
      androidAVDImage: inputContext(WorkflowInputs.androidAVDImage),
      androidAVDDevice: inputContext(WorkflowInputs.androidAVDDevice),
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
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
