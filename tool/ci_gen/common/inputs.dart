import '../types/input.dart';
import 'api/workflow_input.dart';

abstract class WorkflowInputs {
  WorkflowInputs._();

  static Inputs buildInputs(Iterable<WorkflowInput> inputs) => {
        for (final input in inputs) input.name: input.input,
      };

  static WorkflowInput dartSdkVersion() => const WorkflowInput(
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

  static WorkflowInput unitTestPaths() => const WorkflowInput(
        name: 'unitTestPaths',
        input: Input(
          type: Type.string,
          required: false,
          defaultValue: 'test',
          description: 'Specifiy directories or paths of unit tests to run. '
              'By default, all test in the test directory are run.',
        ),
      );

  static WorkflowInput integrationTestPaths() => const WorkflowInput(
        name: 'integrationTestPaths',
        input: Input(
          type: Type.string,
          required: false,
          description:
              'Specifiy directories or paths of integration tests to run. '
              'By default, no integration test are run.',
        ),
      );

  static WorkflowInput integrationTestSetup() => const WorkflowInput(
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

  static WorkflowInput minCoverage() => const WorkflowInput(
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

  static WorkflowInput coverageExclude() => const WorkflowInput(
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

abstract class WorkflowInputGroups {
  WorkflowInputGroups._();

  static const dartSdk = [
    WorkflowInputs.dartSdkVersion,
  ];

  static const testing = [
    WorkflowInputs.unitTestPaths,
    WorkflowInputs.integrationTestPaths,
    WorkflowInputs.integrationTestSetup,
  ];

  static const coverage = [
    WorkflowInputs.minCoverage,
    WorkflowInputs.coverageExclude,
  ];
}
