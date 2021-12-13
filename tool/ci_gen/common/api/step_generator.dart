import '../../types/step.dart';
import 'workflow_input.dart';

abstract class StepGenerator {
  StepGenerator._();

  Iterable<WorkflowInput> get inputs;

  Iterable<Step> call();
}
