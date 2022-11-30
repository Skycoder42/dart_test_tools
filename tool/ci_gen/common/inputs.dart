import '../types/input.dart';
import 'api/workflow_input.dart';

abstract class WorkflowInputs {
  WorkflowInputs._();

  static Inputs buildInputs(Iterable<WorkflowInput> inputs) => {
        for (final input in inputs) input.name: input.input,
      };

  static const repository = WorkflowInput(
    name: 'repository',
    input: Input(
      type: Type.string,
      required: false,
      description: 'The repository to check out. Passed as "repository" to '
          '"actions/checkout".',
    ),
  );

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
      defaultValue: '',
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

  static final platforms = WorkflowInputBuilder<List<String>>(
    name: 'platforms',
    builder: (defaultPlatforms) => Input.json(
      required: false,
      defaultValue: defaultPlatforms,
      description: '''
A JSON-Formatted list of platforms that unit and integration tests should be run on.
By default, all platforms are active. The available platforms are:
${defaultPlatforms.map((p) => '- $p').join('\n')}
''',
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

  static final publishExclude = WorkflowInput(
    name: 'publishExclude',
    input: Input.json(
      required: false,
      defaultValue: const <String>[],
      description: '''
Specify a JSON array of paths to be excluded from publishing.
Example: '["secrets.txt","debug.log"]'
''',
    ),
  );

  static const extendedAnalyzerArgs = WorkflowInput(
    name: 'extendedAnalyzerArgs',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '',
      description: '''
Additional arguments to pass to the dart_test_tools:lint tool when running the
extended linters step. Can for example be used to enable or disable specific
linters.
''',
    ),
  );

  static const unitTestPaths = WorkflowInput(
    name: 'unitTestPaths',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'test',
      description: 'Specifiy directories or paths of unit tests to run. '
          'By default, all test in the test directory are run.',
    ),
  );

  static const integrationTestPaths = WorkflowInput(
    name: 'integrationTestPaths',
    input: Input(
      type: Type.string,
      required: false,
      description: 'Specifiy directories or paths of integration tests to run. '
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

  static const publish = WorkflowInput(
    name: 'publish',
    input: Input(
      type: Type.boolean,
      required: false,
      defaultValue: true,
      description: 'Publish to pub.dev, if a new release was created. Enabled '
          'by default. Requires the PUB_DEV_CREDENTIALS secret to be set.',
    ),
  );

  static const targets = WorkflowInput(
    name: 'targets',
    input: Input(
      type: Type.string,
      required: true,
      description: '''
The names of the targets to be compiled. Must be JSON array of strings, each
string beeing the name of a file in the bin/ folder, without the dart extension.

Example:
["my-app"]
''',
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
      defaultValue: 'system-images;android-31;default;x86_64',
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

  static const createAurUpdate = WorkflowInput(
    name: 'createAurUpdate',
    input: Input(
      type: Type.boolean,
      required: true,
      description:
          'A boolean indicating whether the AUR-Deploy step should run.',
    ),
  );
}
