import '../common/api/workflow_input.dart';
import '../common/jobs/validate_coverage_job_builder.dart';
import '../common/inputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/flutter_analyze_job_builder.dart';
import 'jobs/flutter_integration_test_job_builder.dart';
import 'jobs/flutter_unit_test_job_builder.dart';

abstract class FlutterWorkflow {
  FlutterWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();

    final analyzeJobBuilder = FlutterAnalyzeJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      analyzeImage: inputContext(WorkflowInputs.analyzeImage),
      panaScoreThreshold: inputContext(WorkflowInputs.panaScoreThreshold),
    );
    final unitTestBuilder = FlutterUnitTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
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
    final integrationTestBuilder = FlutterIntegrationTestJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      integrationTestSetup: inputContext(WorkflowInputs.integrationTestSetup),
      integrationTestPaths: inputContext(WorkflowInputs.integrationTestPaths),
      integrationTestProject:
          inputContext(WorkflowInputs.integrationTestProject),
      integrationTestCacheConfig:
          inputContext(WorkflowInputs.integrationTestCacheConfig),
      androidAVDImage: inputContext(WorkflowInputs.androidAVDImage),
      androidAVDDevice: inputContext(WorkflowInputs.androidAVDDevice),
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
