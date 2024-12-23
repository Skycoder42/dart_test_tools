import '../../types/expression.dart';
import '../api/job_config.dart';
import '../inputs.dart';

base mixin CoverageBuilderConfig on JobConfig {
  late final minCoverage = inputContext(WorkflowInputs.minCoverage);
  late final runCoverageExpression = createRunCoverageExpression(minCoverage);

  static Expression createRunCoverageExpression(Expression minCoverage) =>
      minCoverage > const Expression.literal(0);
}
