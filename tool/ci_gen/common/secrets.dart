import '../types/secret.dart';
import 'api/workflow_secret.dart';

abstract class WorkflowSecrets {
  WorkflowSecrets._();

  static const pubDevCredentials = WorkflowSecret(
    name: 'PUB_DEV_CREDENTIALS',
    secret: Secret(
      required: false,
      description: 'The JSON-encoded credentials to log into pub.dev.',
    ),
  );

  static const integrationTestEnvVars = WorkflowSecret(
    name: 'integrationTestEnvVars',
    secret: Secret(
      required: false,
      description: r'''
Secret environment variables to be set for the integration test run step.
Pass a JSON object with key value pairs of variables. You should only use
secrets for the values of these objects.

Example:
{
  "MY_API_KEY": "${{ secrets.MY_API_KEY }}"
}
''',
    ),
  );
}
