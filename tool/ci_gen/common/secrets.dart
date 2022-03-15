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

  static const integrationTestVmArgs = WorkflowSecret(
    name: 'integrationTestVmArgs',
    secret: Secret(
      required: false,
      description:
          'Additional args to be passed to dart before test. Useful for '
          'setting defines. Typically contains secrets like API keys, '
          'thus defined as a secret.',
    ),
  );
}
