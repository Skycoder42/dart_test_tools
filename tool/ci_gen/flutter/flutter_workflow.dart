import '../common/api/workflow_input.dart';
import '../common/api/workflow_secret.dart';
import '../common/builders/validate_coverage_job_builder.dart';
import '../common/inputs.dart';
import '../common/secrets.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/flutter_analyze_job_builder.dart';
import 'builders/flutter_bitrise_job_builder.dart';
import 'builders/flutter_integration_test_job_builder.dart';
import 'builders/flutter_unit_test_job_builder.dart';

abstract class FlutterWorkflow {
  FlutterWorkflow._();

  static Workflow buildWorkflow() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();

    final analyzeJobBuilder = FlutterAnalyzeJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      analyzeImage: inputContext(WorkflowInputs.analyzeImage),
      extendedAnalyzerArgs: inputContext(WorkflowInputs.extendedAnalyzerArgs),
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
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );
    final validateCoverageBuilder = ValidateCoverageJobBuilder(
      unitTestJobId: unitTestBuilder.id,
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
      minCoverage: inputContext(WorkflowInputs.minCoverage),
      coverageExclude: inputContext(WorkflowInputs.coverageExclude),
      platforms: inputContext.builder(WorkflowInputs.platforms),
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
      platforms: inputContext.builder(WorkflowInputs.platforms),
    );
    final bitriseIntegrationTestBuilder = FlutterBitriseJobBuilder(
      analyzeJobId: analyzeJobBuilder.id,
      bitriseAppSlug: inputContext(WorkflowInputs.bitriseAppSlug),
      bitriseWorkflowId: inputContext(WorkflowInputs.bitriseWorkflowId),
      bitrisePat: secretContext(WorkflowSecrets.bitrisePat),
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
        bitriseIntegrationTestBuilder.id: bitriseIntegrationTestBuilder.build(),
      },
    );
  }
}
