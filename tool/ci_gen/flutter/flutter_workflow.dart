import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/jobs/validate_coverage_job_builder.dart';
import '../common/outputs.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/android_integration_test_job_builder.dart';
import 'jobs/desktop_integration_test_job_builder.dart';
import 'jobs/flutter_analyze_job_builder.dart';
import 'jobs/flutter_unit_test_job_builder.dart';
import 'jobs/ios_integration_test_job_builder.dart';
import 'jobs/web_integration_test_job_builder.dart';

class FlutterWorkflow implements WorkflowBuilder {
  const FlutterWorkflow();

  @override
  String get name => 'flutter';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final analyzeJobBuilder = FlutterAnalyzeJobBuilder(
      config: FlutterAnalyzeJobConfig(inputContext, secretContext),
    );
    outputContext.add(
      WorkflowOutputs.enabledPlatforms,
      analyzeJobBuilder.platformsOutput,
    );

    final unitTestBuilder = FlutterUnitTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: FlutterUnitTestJobConfig(inputContext, secretContext),
    );

    final validateCoverageBuilder = ValidateCoverageJobBuilder(
      unitTestJobId: unitTestBuilder.id,
      config: ValidateCoverageJobConfig(inputContext, secretContext),
    );

    final androidIntegrationTestBuilder = AndroidIntegrationTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: AndroidIntegrationTestJobConfig(inputContext, secretContext),
    );

    final iosIntegrationTestBuilder = IosIntegrationTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: IosIntegrationTestJobConfig(inputContext, secretContext),
    );

    final desktopIntegrationTestBuilder = DesktopIntegrationTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: DesktopIntegrationTestJobConfig(inputContext, secretContext),
    );

    final webIntegrationTestBuilder = WebIntegrationTestJobBuilder(
      enabledPlatformsOutput: analyzeJobBuilder.platformsOutput,
      config: WebIntegrationTestJobConfig(inputContext, secretContext),
    );

    return Workflow(
      jobs: {
        analyzeJobBuilder.id: analyzeJobBuilder.build(),
        unitTestBuilder.id: unitTestBuilder.build(),
        validateCoverageBuilder.id: validateCoverageBuilder.build(),
        androidIntegrationTestBuilder.id: androidIntegrationTestBuilder.build(),
        iosIntegrationTestBuilder.id: iosIntegrationTestBuilder.build(),
        desktopIntegrationTestBuilder.id: desktopIntegrationTestBuilder.build(),
        webIntegrationTestBuilder.id: webIntegrationTestBuilder.build(),
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
