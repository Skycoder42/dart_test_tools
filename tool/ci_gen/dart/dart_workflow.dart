import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../common/jobs/validate_coverage_job_builder.dart';
import '../common/outputs.dart';
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
    final outputContext = WorkflowOutputContext();

    final analyzeJobBuilder = DartAnalyzeJobBuilder(
      config: DartAnalyzeJobConfig(
        dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
        buildRunner: inputContext(WorkflowInputs.buildRunner),
        buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
        removePubspecOverrides:
            inputContext(WorkflowInputs.removePubspecOverrides),
        localResolution: inputContext(WorkflowInputs.localResolution),
        analyzeImage: inputContext(WorkflowInputs.analyzeImage),
        panaScoreThreshold: inputContext(WorkflowInputs.panaScoreThreshold),
      ),
    );
    outputContext.add(
      WorkflowOutputs.enabledPlatforms,
      analyzeJobBuilder.platformsOutput,
    );

    final unitTestBuilder = DartUnitTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: DartUnitTestJobConfig(
        dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
        buildRunner: inputContext(WorkflowInputs.buildRunner),
        buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
        removePubspecOverrides:
            inputContext(WorkflowInputs.removePubspecOverrides),
        localResolution: inputContext(WorkflowInputs.localResolution),
        unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
        minCoverage: inputContext(WorkflowInputs.minCoverage),
      ),
    );

    final validateCoverageBuilder = ValidateCoverageJobBuilder(
      unitTestJobId: unitTestBuilder.id,
      config: ValidateCoverageJobConfig(
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        unitTestPaths: inputContext(WorkflowInputs.unitTestPaths),
        minCoverage: inputContext(WorkflowInputs.minCoverage),
        coverageExclude: inputContext(WorkflowInputs.coverageExclude),
      ),
    );

    final integrationTestBuilder = DartIntegrationTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: DartIntegrationTestJobConfig(
        dartSdkVersion: inputContext(WorkflowInputs.dartSdkVersion),
        workingDirectory: inputContext(WorkflowInputs.workingDirectory),
        artifactDependencies: inputContext(WorkflowInputs.artifactDependencies),
        buildRunner: inputContext(WorkflowInputs.buildRunner),
        buildRunnerArgs: inputContext(WorkflowInputs.buildRunnerArgs),
        removePubspecOverrides:
            inputContext(WorkflowInputs.removePubspecOverrides),
        localResolution: inputContext(WorkflowInputs.localResolution),
        integrationTestPaths: inputContext(WorkflowInputs.integrationTestPaths),
        integrationTestSetup: inputContext(WorkflowInputs.integrationTestSetup),
        integrationTestEnvVars:
            secretContext(WorkflowSecrets.integrationTestEnvVars),
        integrationTestCacheConfig:
            inputContext(WorkflowInputs.integrationTestCacheConfig),
      ),
    );

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: inputContext.createInputs(),
          secrets: secretContext.createSecrets(),
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
