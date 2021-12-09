import '../../types/job.dart';
import 'workflow_input.dart';

abstract class JobBuilder {
  JobBuilder._();

  String get name;

  Iterable<WorkflowInput> get inputs;

  Job build();
}
