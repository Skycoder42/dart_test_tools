import '../types/input.dart';
import 'api/workflow_input.dart';
import 'tools.dart';

abstract class WorkflowInputs {
  WorkflowInputs._();

  static Inputs buildInputs(Iterable<WorkflowInput> inputs) => {
        for (final input in inputs) input.name: input.input,
      };

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
      defaultValue: 11,
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

  static const extendedAnalyzerArgs = WorkflowInput(
    name: 'extendedAnalyzerArgs',
    input: Input(
      type: Type.string,
      required: false,
      description: '''
Additional arguments to pass to the dart_test_tools:lint tool when running the
extended linters step. Can for example be used to enable or disable specific
linters.
''',
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
      defaultValue: 'system-images;android-33;google_apis;x86_64',
      description: 'The AVD-Image to be used for android integration testing',
    ),
  );

  static const androidAVDDevice = WorkflowInput(
    name: 'androidAVDDevice',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'pixel_4',
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

  static const dockerImageName = WorkflowInput(
    name: 'dockerImageName',
    input: Input(
      type: Type.string,
      required: true,
      description:
          'The name (e.g. owern/image) of the image to be built and published. '
          'The name is combined with dockerImageTags - See below for details.',
    ),
  );

  static const dockerImageTags = WorkflowInput(
    name: 'dockerImageTags',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'latest',
      description:
          'A comma or newline separated list of docker tag versions to be '
          'built and published. By default, only "latest" is used. These tags '
          'are joined with the dockerImageName to generate the full tag '
          'values. These are the passed to ${Tools.dockerBuildAndPushAction} '
          'as "tags".',
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
      description: 'The released version to upload additional files to.',
    ),
  );
}
