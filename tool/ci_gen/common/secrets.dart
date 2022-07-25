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
workingDirectory containing those values. You can use the 'TestEnv.load()' of
the dart_test_tools package to read them in your integration tests.

Example:
MY_API_KEY=<reference secret here>"
''',
    ),
  );

  static const aurSshPrivateKey = WorkflowSecret(
    name: 'AUR_SSH_PRIVATE_KEY',
    secret: Secret(
      required: true,
      description: 'The ASCII armored private SSH key to use to push changes '
          'to the AUR. The corresponding public key must have been added at '
          'https://aur.archlinux.org/ under "My Account".',
    ),
  );
}
