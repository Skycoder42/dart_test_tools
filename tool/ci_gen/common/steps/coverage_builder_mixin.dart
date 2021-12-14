import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';

mixin CoverageBuilderMixin {
  Expression get minCoverage;

  @protected
  Expression get runCoverageExpression =>
      Expression('${minCoverage.value} > 0');
}
