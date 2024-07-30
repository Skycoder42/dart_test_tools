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
}

abstract base class Functions {
  const Functions._();

  static const always = Expression('always()');
}
