import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/input.dart';
import '../api/workflow_input.dart';

mixin CoverageBaseBuilderMixin {
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
  String get runCoverageExpression => '${minCoverageInput.expression} > 0';

  @protected
  Iterable<WorkflowInput> get coverageBaseInputs => [minCoverageInput];
}
