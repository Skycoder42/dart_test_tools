import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import 'project_setup_builder.dart';

mixin PlatformsBuilderMixin {
  @protected
  Expression get shouldRunExpression =>
      ProjectSetupBuilder.shouldRunOutput.expression;
}
