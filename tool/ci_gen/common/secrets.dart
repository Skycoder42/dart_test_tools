import '../types/secret.dart';
import 'api/workflow_secret.dart';

abstract class WorkflowSecrets {
  WorkflowSecrets._();

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

  static const dockerHubUsername = WorkflowSecret(
    name: 'dockerHubUsername',
    secret: Secret(
      required: true,
      description: 'The user name to log into docker hub with.',
    ),
  );

  static const dockerHubToken = WorkflowSecret(
    name: 'dockerHubToken',
    secret: Secret(
      required: true,
      description: 'The personal access token to log into docker hub with.',
    ),
  );

  static const githubToken = WorkflowSecret(
    name: 'githubToken',
    secret: Secret(
      required: true,
      description:
          'The personal access token to create new releases with. Is required, as the default '
          'github workflow token does not trigger workflows when creating releases.',
    ),
  );

  static const dartDefines = WorkflowSecret(
    name: 'dartDefines',
    secret: Secret(
      required: false,
      description: '''
Additional dart-defines that are passed to the build command. In the format of:

VARIABLE1=value1
VARIABLE2=value2
''',
    ),
  );

  static const keystore = WorkflowSecret(
    name: 'keystore',
    secret: Secret(
      required: true,
      description:
          'A base64 encoded java keystore used for signing the android app. '
          'Use "cat keystore.jks | openssl base64" to encode it.',
    ),
  );

  static const keystorePassword = WorkflowSecret(
    name: 'keystorePassword',
    secret: Secret(
      required: true,
      description: 'The primary password for the signing keystore. '
          'Must be the password for both, keystore and signing key.',
    ),
  );

  static const sentryAuthToken = WorkflowSecret(
    name: 'sentryAuthToken',
    secret: Secret(
      required: false,
      description: 'A sentry authentication token. '
          'If specified, debug symbols will be uploaded to sentry. '
          'If not specified (the default), no debug symbols are uploaded.',
    ),
  );

  static const googlePlayKey = WorkflowSecret(
    name: 'googlePlayKey',
    secret: Secret(
      required: true,
      description: 'The google play api upload JSON key. '
          'Needed by fastlane to actually publish the app.',
    ),
  );

  static const packagecloudToken = WorkflowSecret(
    name: 'packagecloudToken',
    secret: Secret(
      required: true,
      description: 'The access token for the packagecloud upload.',
    ),
  );
}
