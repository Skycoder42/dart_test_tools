import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/jobs/validate_coverage_job_builder.dart';
import '../common/inputs.dart';
import '../common/outputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/flutter_analyze_job_builder.dart';
import 'jobs/flutter_integration_test_job_builder.dart';
import 'jobs/flutter_unit_test_job_builder.dart';

class FlutterWorkflow implements WorkflowBuilder {
  const FlutterWorkflow();

  @override
  String get name => 'flutter';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final outputContext = WorkflowOutputContext();

    final analyzeJobBuilder = FlutterAnalyzeJobBuilder(
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      removePubspecOverrides:
          inputContext(WorkflowInputs.removePubspecOverrides),
      analyzeImage: inputContext(WorkflowInputs.analyzeImage),
      panaScoreThreshold: inputContext(WorkflowInputs.panaScoreThreshold),
    );
    outputContext.add(
      WorkflowOutputs.enabledPlatforms,
      analyzeJobBuilder.platformsOutput,
    );

    final unitTestBuilder = FlutterUnitTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      removePubspecOverrides:
          inputContext(WorkflowInputs.removePubspecOverrides),
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
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      flutterSdkChannel: inputContext(WorkflowInputs.flutterSdkChannel),
      javaJdkVersion: inputContext(WorkflowInputs.javaJdkVersion),
      workingDirectory: inputContext(WorkflowInputs.workingDirectory),
      artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
      buildRunner: inputContext(WorkflowInputs.buildRunner),
      buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
      removePubspecOverrides:
          inputContext(WorkflowInputs.removePubspecOverrides),
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
          outputs: outputContext.createOutputs(),
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
