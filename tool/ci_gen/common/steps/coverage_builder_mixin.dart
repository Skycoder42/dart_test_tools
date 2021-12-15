import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';

mixin CoverageBuilderMixin {
  Expression get minCoverage;

  @protected
  Expression get runCoverageExpression =>
      createRunCoverageExpression(minCoverage);

  static Expression createRunCoverageExpression(Expression minCoverage) =>
      minCoverage > const Expression.literal(0);
}
