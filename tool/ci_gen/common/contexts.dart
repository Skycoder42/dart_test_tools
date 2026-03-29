import '../types/expression.dart';

abstract base class Runner {
  const Runner._();

  static const temp = Expression('runner.temp');

  static const os = Expression('runner.os');
}

abstract base class Github {
  const Github._();

  static const ref = Expression('github.ref');

  static const refName = Expression('github.ref_name');

  static const sha = Expression('github.sha');

  static const workspace = Expression('github.workspace');

  static const actor = Expression('github.actor');

  static const repository = Expression('github.repository');

  static const repositoryOwner = Expression('github.repository_owner');
}

abstract base class Functions {
  const Functions._();

  static const always = Expression('always()');

  static const success = Expression('success()');

  static const failure = Expression('failure()');

  static Expression format(String message, List<Expression> args) =>
      Expression.invoke('format', [Expression.literal(message), ...args]);

  static Expression fromJson(Expression jsonString) =>
      Expression.invoke('fromJson', [jsonString]);

  static Expression case$(
    List<(Expression, ExpressionOrValue)> cases, [
    ExpressionOrValue? default$,
  ]) => Expression.invoke(
    'case',
    cases.expand((c) => [c.$1, c.$2.asExpression]).followedBy([
      default$?.asExpression ?? .null$,
    ]),
  );
}
