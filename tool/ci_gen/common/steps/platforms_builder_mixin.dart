import 'package:freezed_annotation/freezed_annotation.dart';

import '../api/workflow_input.dart';

mixin PlatformsBuilderMixin {
  WorkflowInput get platforms;

  @protected
  String shouldRunExpression(String platform) =>
      'contains(fromJSON(${platforms.expression}), $platform)';
}
