import '../common/api/workflow_input.dart';

abstract class Expression {
  const Expression._();

  static String literal(String value) => "'$value'";

  static String create(String expression) => '\${{ $expression }}';

  static String input(WorkflowInput input) => '\${{ ${input.expression} }}';

  static String and(String expr1, String expr2, [Iterable<String>? exprs]) =>
      [expr1, expr2, ...?exprs].join(' && ');
}
