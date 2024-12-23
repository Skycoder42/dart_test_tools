import 'package:meta/meta.dart';

import 'workflow_input.dart';
import 'workflow_secret.dart';

abstract base class JobConfig {
  final WorkflowInputContext inputContext;
  final WorkflowSecretContext secretContext;

  @protected
  @mustCallSuper
  void configure() {}

  JobConfig(this.inputContext, this.secretContext) {
    configure();
  }
}
