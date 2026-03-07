import '../common/api/workflow_builder.dart';
import '../common/api/workflow_input.dart';
import '../common/api/workflow_output.dart';
import '../common/api/workflow_secret.dart';
import '../common/inputs.dart';
import '../types/env.dart';
import '../types/expression.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'jobs/android_integration_test_job_builder.dart';
import 'jobs/desktop_integration_test_job_builder.dart';
import 'jobs/ios_integration_test_job_builder.dart';
import 'jobs/web_integration_test_job_builder.dart';

class FlutterIntegrationWorkflow implements WorkflowBuilder {
  const FlutterIntegrationWorkflow();

  @override
  String get name => 'flutter-integration';

  @override
  Workflow build() {
    final inputContext = WorkflowInputContext();
    final secretContext = WorkflowSecretContext();
    final outputContext = WorkflowOutputContext();

    final enabledPlatforms = inputContext(WorkflowInputs.enabledPlatforms);

    final androidIntegrationTestBuilder =
        AndroidIntegrationTestJobBuilder.direct(
          enabledPlatforms: enabledPlatforms,
          config: AndroidIntegrationTestJobConfig(inputContext, secretContext),
        );

    final iosIntegrationTestBuilder = IosIntegrationTestJobBuilder.direct(
      enabledPlatforms: enabledPlatforms,
      config: IosIntegrationTestJobConfig(inputContext, secretContext),
    );

    final desktopIntegrationTestBuilder =
        DesktopIntegrationTestJobBuilder.direct(
          enabledPlatforms: enabledPlatforms,
          config: DesktopIntegrationTestJobConfig(inputContext, secretContext),
        );

    final webIntegrationTestBuilder = WebIntegrationTestJobBuilder.direct(
      enabledPlatforms: enabledPlatforms,
      config: WebIntegrationTestJobConfig(inputContext, secretContext),
    );

    final env = inputContext(WorkflowInputs.env);

    return Workflow(
      jobs: {
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
      env: Env.expression(const Expression('fromJSON')([env])),
    );
  }
}
