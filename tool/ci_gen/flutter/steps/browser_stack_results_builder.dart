import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class BrowserStackResultsBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression integrationTestProject;

  const BrowserStackResultsBuilder({
    required this.workingDirectory,
    required this.integrationTestProject,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Process integration tests results',
          ifExpression: Functions.always,
          run: r'''
set -eo pipefail
result_file=build/test-results.json
echo "Completed BrowserStack test run with status: $(jq -r '.status' "$result_file")"
echo "See results at: https://app-automate.browserstack.com/dashboard/v2/builds/$(jq -r '.id' "$result_file")"
''',
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
      ];
}
