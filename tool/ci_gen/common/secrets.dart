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
      description: '''
Secret environment variables to be set for the integration test run step.
Pass a multi line string of key-value pairs. You should only use
secrets for the values of these objects. The CI will create a .env file in the
workingDirectory containing those values. You can use
https://pub.dev/packages/dotenv to read them in your integration tests.

Example:
MY_API_KEY=<reference secret here>"
''',
    ),
  );
}
