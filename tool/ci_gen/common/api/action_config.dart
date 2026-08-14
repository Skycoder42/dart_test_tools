import 'package:freezed_annotation/freezed_annotation.dart';

import 'workflow_input.dart';

abstract base class ActionConfig {
  final WorkflowInputContext inputContext;

  @protected
  @mustCallSuper
  void configure() {}

  new(this.inputContext) {
    configure();
  }
}
