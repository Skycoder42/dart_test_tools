import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';

mixin PlatformsBuilderMixin {
  Expression get platforms;

  @protected
  Expression shouldRunExpression(Expression platform) =>
      createShouldRunExpression(platforms, platform);

  static Expression createShouldRunExpression(
    Expression platforms,
    Expression platform,
  ) =>
      Expression('contains(fromJSON(${platforms.value}), ${platform.value})');
}
