import '../../types/expression.dart';
import '../api/job_config.dart';

base mixin CoverageBuilderConfig on JobConfig {
  late Expression minCoverage;
  late final Expression runCoverageExpression =
      createRunCoverageExpression(minCoverage);

  static Expression createRunCoverageExpression(Expression minCoverage) =>
      minCoverage > const Expression.literal(0);
}
