import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/step.dart';
import '../api/workflow_input.dart';
import 'platforms_builder_mixin.dart';
import 'project_setup_builder_mixin.dart';

mixin CoverageCollectorBuilderMixin
    on ProjectSetupBuilderMixin, PlatformsBuilderMixin {
  @protected
  final minCoverageInput = const WorkflowInput(
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

  @protected
  bool get needsFormatting;

  @protected
  Iterable<WorkflowInput> get coverageCollectorInputs => [minCoverageInput];

  @protected
  Iterable<Step> createCoverageCollectorSteps({
    required String platformExpression,
    required String lcovCleanCommandExpression,
  }) =>
      [
        if (needsFormatting)
          Step.run(
            name: 'Convert coverage data to lcov format',
            ifExpression: _coverageExpression(platformExpression),
            run: '$runTool coverage:format_coverage --lcov --check-ignore '
                '--in=coverage --out=coverage/lcov.info '
                '--packages=.packages --report-on=lib',
            workingDirectory: Expression.input(workingDirectoryInput),
          ),
        Step.run(
          name: 'Normalize coverage paths',
          ifExpression: _coverageExpression(platformExpression),
          run: Expression.create(lcovCleanCommandExpression),
          workingDirectory: Expression.input(workingDirectoryInput),
        ),
        Step.uses(
          name: 'Upload coverage data',
          ifExpression: _coverageExpression(platformExpression),
          uses: 'actions/upload-artifact@v2', // TODO globalize
          withArgs: {
            'name': 'coverage-info-${Expression.create(platformExpression)}',
            'path':
                '${Expression.input(workingDirectoryInput)}/coverage/lcov.info',
          },
        ),
      ];

  String _coverageExpression(String platformExpression) => Expression.and(
        '${minCoverageInput.expression} > 0',
        shouldRunExpression(platformExpression),
      );
}
