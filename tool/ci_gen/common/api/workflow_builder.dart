import '../../types/workflow.dart';

abstract interface class WorkflowBuilder {
  String get name;

  Workflow build();
}
