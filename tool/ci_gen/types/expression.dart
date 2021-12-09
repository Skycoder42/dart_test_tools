import '../common/api/workflow_input.dart';

abstract class Expression {
  const Expression._();

  static String create(String expression) => '\${{ $expression }}';

  static String input(WorkflowInput input) => '\${{ ${input.expression} }}';
}
