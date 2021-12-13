import '../types/input.dart';
import 'api/workflow_input.dart';

abstract class WorkflowInputs {
  WorkflowInputs._();

  static Inputs buildInputs(Iterable<WorkflowInput> inputs) => {
        for (final input in inputs) input.name: input.input,
      };

  static const repositoryInput = WorkflowInput(
    name: 'repository',
    input: Input(
      type: Type.string,
      required: false,
      description: 'The repository to check out. Passed as "repository" to '
          '"actions/checkout".',
    ),
  );

  static const workingDirectoryInput = WorkflowInput(
    name: 'workingDirectory',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '.',
      description: 'The root directory of the dart package to build and test.',
    ),
  );

  static const buildRunnerInput = WorkflowInput(
    name: 'buildRunner',
    input: Input(
      type: Type.boolean,
      required: false,
      defaultValue: false,
      description: 'Specify whether build_runner is used in the project '
          '(defaults to false).',
    ),
  );

  static const dartSdkVersion = WorkflowInput(
    name: 'dartSdkVersion',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'stable',
      description: 'The Dart-SDK version. '
          'Passed as "sdk" to "dart-lang/setup-dart"',
    ),
  );

  static final platforms = WorkflowInputBuilder(
    name: 'platforms',
    builder: (List<String> defaultPlatforms) => Input.json(
      required: false,
      defaultValue: defaultPlatforms,
      description: '''
A JSON-Formatted list of platforms that unit and integration tests should be run on.
By default, all platforms are active. The available platforms are:
${defaultPlatforms.map((p) => '- $p').join('\n')}
''',
    ),
  );

  static const analyzeImageInput = WorkflowInput(
    name: 'analyzeImage',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'ubuntu-latest',
      description: 'The Runner-Image to use for the analyze step. '
          'Uses ubuntu-latest by default',
    ),
  );

  static const publishExcludeInput = WorkflowInput(
    name: 'publishExclude',
    input: Input(
      type: Type.string,
      required: false,
      description: 'Specify a list of colon separated paths to be excluded '
          'from publishing.',
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

  static const integrationTestSetup = WorkflowInput(
    name: 'integrationTestSetup',
    input: Input(
      type: Type.string,
      required: false,
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
          '"VeryGoodOpenSource/very_good_coverage"',
    ),
  );

  static const coverageExclude = WorkflowInput(
    name: 'coverageExclude',
    input: Input(
      type: Type.string,
      required: false,
      description: 'Files to exclude from test coverage. Passed as '
          'command line arguments to a bash script. Excludes should be '
          'properly escaped, e.g. \'config.dart "**/*.g.dart"\'',
    ),
  );
}
