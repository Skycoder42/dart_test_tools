import '../types/input.dart';
import 'api/workflow_input.dart';
import 'tools.dart';

abstract base class WorkflowInputs {
  WorkflowInputs._();

  static const workingDirectory = WorkflowInput(
    name: 'workingDirectory',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '.',
      description: 'The root directory of the dart package to build and test.',
    ),
  );

  static const buildRunner = WorkflowInput(
    name: 'buildRunner',
    input: Input(
      type: Type.boolean,
      required: false,
      defaultValue: false,
      description: 'Specify whether build_runner is used in the project '
          '(defaults to false).',
    ),
  );

  static const buildRunnerArgs = WorkflowInput(
    name: 'buildRunnerArgs',
    input: Input(
      type: Type.string,
      required: false,
      description:
          'Optional additional arguments to be passed to the build runner.',
    ),
  );

  static const dartSdkVersion = WorkflowInput(
    name: 'dartSdkVersion',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'stable',
      description: 'The Dart-SDK version. '
          'Passed as "sdk" to "dart-lang/setup-dart".',
    ),
  );

  static const flutterSdkChannel = WorkflowInput(
    name: 'flutterSdkChannel',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'stable',
      description: 'The Flutter-SDK channel. '
          'Passed as "channel" to "subosito/flutter-action".',
    ),
  );

  static const javaJdkVersion = WorkflowInput(
    name: 'javaJdkVersion',
    input: Input(
      type: Type.number,
      required: false,
      defaultValue: 17,
      description: 'The Java-SDK version (mayor only). '
          'Passed as "java-version" to "actions/setup-java".',
    ),
  );

  static const analyzeImage = WorkflowInput(
    name: 'analyzeImage',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'ubuntu-latest',
      description: 'The Runner-Image to use for the analyze step. '
          'Uses ubuntu-latest by default.',
    ),
  );

  static const panaScoreThreshold = WorkflowInput(
    name: 'panaScoreThreshold',
    input: Input(
      type: Type.number,
      required: false,
      defaultValue: 0,
      description: 'The threshold that the pana score is allowed '
          'to be below the maximum value.',
    ),
  );

  static const unitTestPaths = WorkflowInput(
    name: 'unitTestPaths',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'test',
      description: 'Specify directories or paths of unit tests to run. '
          'By default, all test in the test directory are run.',
    ),
  );

  static const integrationTestPaths = WorkflowInput(
    name: 'integrationTestPaths',
    input: Input(
      type: Type.string,
      required: false,
      description: 'Specify directories or paths of integration tests to run. '
          'By default, no integration test are run.',
    ),
  );

  static final integrationTestSetup = WorkflowInput(
    name: 'integrationTestSetup',
    input: Input.json(
      required: false,
      defaultValue: const <String, String>{},
      description: '''
A JSON-Matrix with extra setup steps for each platform.
contains key-value pairs for each platform with a command to be invoked.
The possible keys are the same as the platforms defined in 'platforms'.

Example:
{
  "linux": "dart run tools/install-deps.dart",
  "web": "./setup-web.sh"
}
''',
    ),
  );

  static const integrationTestCacheConfig = WorkflowInput(
    name: 'integrationTestCacheConfig',
    input: Input(
      type: Type.string,
      required: false,
      description: '''
A JSON-Matrix a caching configuration, if needed. Can be used to enable caching
for expensive integration test setup scenarios.

Example:
{
  "key": "test-cache-key",
  "path": "path/to/cache-dir"
}
''',
    ),
  );

  static const minCoverage = WorkflowInput(
    name: 'minCoverage',
    input: Input(
      type: Type.number,
      required: false,
      defaultValue: 95,
      description:
          'Minimal coverage (in percent) required for the CI to succeed. '
          'Passed as "min_coverage" to '
          '"VeryGoodOpenSource/very_good_coverage".',
    ),
  );

  static const coverageExclude = WorkflowInput(
    name: 'coverageExclude',
    input: Input(
      type: Type.string,
      required: false,
      description: 'Files to exclude from test coverage. Passed as '
          'command line arguments to a bash script. Excludes should be '
          'properly escaped, e.g. \'config.dart "**/*.g.dart"\'.',
    ),
  );

  static const releaseRef = WorkflowInput(
    name: 'releaseRef',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'refs/heads/main',
      description: 'The git ref that is allowed to publish releases.',
    ),
  );

  static const tagPrefix = WorkflowInput(
    name: 'tagPrefix',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'v',
      description: 'The prefix of git tags. The tag is the prefix, '
          'followed by the package version.',
    ),
  );

  static const flutter = WorkflowInput(
    name: 'flutter',
    input: Input(
      type: Type.boolean,
      required: false,
      defaultValue: false,
      description:
          'Specifies, whether the package is a dart or a flutter package.',
    ),
  );

  static const integrationTestProject = WorkflowInput(
    name: 'integrationTestProject',
    input: Input(
      type: Type.string,
      required: false,
      description:
          'Specifies the project in which integration tests are placed. '
          'Useful in case of flutter libraries, where integration tests are '
          'typically inside the example instead of the package itself',
    ),
  );

  static const androidAVDImage = WorkflowInput(
    name: 'androidAVDImage',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'system-images;android-34;google_apis;x86_64',
      description: 'The AVD-Image to be used for android integration testing',
    ),
  );

  static const androidAVDDevice = WorkflowInput(
    name: 'androidAVDDevice',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'pixel_7',
      description:
          'The AVD device template to be used for android integration testing',
    ),
  );

  static const prePublish = WorkflowInput(
    name: 'prePublish',
    input: Input(
      type: Type.string,
      required: false,
      description: 'A command to be run before publishing the package',
    ),
  );

  static const extraArtifacts = WorkflowInput(
    name: 'extraArtifacts',
    input: Input(
      type: Type.string,
      required: false,
      description: '''
A JSON-Matrix a artifact download configuration, if needed. Can be used to
download artifacts before publishing the package. Can be combined with
`prePublish` to process the downloaded artifacts.

Example:
{
  "name": "test-artifact",
  "path": "path/to/artifact-dir"
}
''',
    ),
  );

  static const dockerPlatforms = WorkflowInput(
    name: 'dockerPlatforms',
    input: Input(
      type: Type.string,
      required: false,
      description:
          'A comma or newline separated list of docker target platforms to '
          'build the docker image for. If not specified, the image is built '
          'for all available platforms. Passed to '
          '${Tools.dockerBuildAndPushAction} as "platforms".',
    ),
  );

  static const dockerBuildArgs = WorkflowInput(
    name: 'dockerBuildArgs',
    input: Input(
      type: Type.string,
      required: false,
      description:
          'A newline separated list of docker build arguments to build the '
          'docker image with. Passed to ${Tools.dockerBuildAndPushAction} as '
          '"build-args"',
    ),
  );

  static const imageName = WorkflowInput(
    name: 'imageName',
    input: Input(
      type: Type.string,
      required: true,
      description:
          'The name (e.g. owner/image) of the image to be built and published. '
          'The name is combined with generated version tags - '
          'See version for details.',
    ),
  );

  static const extraTags = WorkflowInput(
    name: 'extraTags',
    input: Input(
      type: Type.string,
      required: false,
      description:
          'A newline separated list of additional docker tags to be published.',
    ),
  );

  static const persistCredentials = WorkflowInput(
    name: 'persistCredentials',
    input: Input(
      type: Type.boolean,
      required: false,
      defaultValue: false,
      description:
          'Specifies, whether git credentials should be persisted for the run. '
          'Might be needed in case the repository is a private repository to '
          'figure out whether a new release is required or not.',
    ),
  );

  static const version = WorkflowInput(
    name: 'version',
    input: Input(
      type: Type.string,
      required: true,
      description:
          'The released version to upload additional files to or images for.',
    ),
  );

  static const artifactDependencies = WorkflowInput(
    name: 'artifactDependencies',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '',
      description: 'A space-separated list of package names that should be '
          'downloaded from the artifacts and overwritten for the workflow. '
          'The packages should be space separated and placed in a single line. '
          'You can use the YAML ">-" for that.',
    ),
  );

  static const removePubspecOverrides = WorkflowInput(
    name: 'removePubspecOverrides',
    input: Input(
      type: Type.boolean,
      required: false,
      defaultValue: true,
      description: 'Disables pubspec_overrides.yaml cleanup if set to false.',
    ),
  );

  static const enabledPlatforms = WorkflowInput(
    name: 'enabledPlatforms',
    input: Input(
      type: Type.string,
      required: true,
      description:
          'A JSON-encoded list of all platforms that this project can build/run for.',
    ),
  );

  static const buildNumberArgs = WorkflowInput(
    name: 'buildNumberArgs',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '',
      description: 'Additional args for the build number generator.',
    ),
  );

  static const primaryLocale = WorkflowInput(
    name: 'primaryLocale',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'en-US',
      description: 'The default locale of the app. '
          'This is used to set the language of the generated changelogs',
    ),
  );

  static const googlePlayTrack = WorkflowInput(
    name: 'googlePlayTrack',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'production',
      description: 'The google play release track to publish the app to '
          '(Standard tracks are: production, beta, alpha, internal).',
    ),
  );

  static const googlePlayReleaseStatus = WorkflowInput(
    name: 'googlePlayReleaseStatus',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'completed',
      description: 'The google play release status after publishing the app '
          '(completed, draft, halted, inProgress).',
    ),
  );

  static const archivePrefix = WorkflowInput(
    name: 'archivePrefix',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'binaries',
      description: 'The prefix of the binary archive files that contain '
          'the actual binaries. Will be suffixed with the platform name.',
    ),
  );

  static const packagecloudRepository = WorkflowInput(
    name: 'packagecloudRepository',
    input: Input(
      type: Type.string,
      required: true,
      description: 'The packagecloud repository to publish to.',
    ),
  );

  static const flatpakSdkVersion = WorkflowInput(
    name: 'flatpakSdkVersion',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '23.08',
      description: 'The version of the freedesktop sdk and runtime being used.',
    ),
  );

  static const flatpakPlatformImage = WorkflowInput(
    name: 'flatpakPlatformImage',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'flatpak-github-actions:gnome-46',
      description: 'The docker image to be used to build the bundle with',
    ),
  );

  static const bundleName = WorkflowInput(
    name: 'bundleName',
    input: Input(
      type: Type.string,
      required: true,
      description: 'The output flatpak bundle name.',
    ),
  );

  static const manifestPath = WorkflowInput(
    name: 'manifestPath',
    input: Input(
      type: Type.string,
      required: true,
      description: 'The path to the flatpak manifest to be built.',
    ),
  );

  static const dmgConfigPath = WorkflowInput(
    name: 'dmgConfigPath',
    input: Input(
      type: Type.string,
      required: true,
      description: 'Path to the configuration file for the appdmg tool.',
    ),
  );

  static const targetRepo = WorkflowInput(
    name: 'targetRepo',
    input: Input(
      type: Type.string,
      required: false,
      description: 'The repository identifier (<owner>/<repo>) '
          'to which the cask should be published.',
    ),
  );

  static const baseHref = WorkflowInput(
    name: 'baseHref',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '/',
      description:
          'The base href for the generated web application. Defaults to "/".',
    ),
  );

  static final browserStackDevices = WorkflowInput(
    name: 'browserStackDevices',
    input: Input.json(
      required: false,
      defaultValue: const [
        {'device': '.*'},
      ],
      description: 'The devices to be used with BrowserStack.',
    ),
  );
}
