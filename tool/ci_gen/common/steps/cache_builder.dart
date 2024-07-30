import '../../types/env.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class CacheBuilder implements StepBuilder {
  final StepId cacheStepId;
  final ExpressionOrValue platform;
  final Expression cacheConfig;
  final Expression? ifExpression;

  const CacheBuilder({
    required this.cacheStepId,
    required this.platform,
    required this.cacheConfig,
    this.ifExpression,
  });

  static Env createEnv(StepId cacheStepId) => Env({
        'CACHE_HIT': cacheStepId.output('cache-hit').expression.toString(),
      });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Restore integration test cache',
          id: cacheStepId,
          uses: Tools.actionsCache,
          ifExpression: cacheConfig.ne(Expression.empty) & ifExpression,
          withArgs: <String, dynamic>{
            for (final key in [
              'key',
              'path',
              'restore-keys',
              'upload-chunk-size',
            ])
              key: _cacheConfig(key),
          },
        ),
      ];

  String _cacheConfig(String key) {
    final expression = Expression(
      "fromJSON(${cacheConfig.value})['$key']",
    );
    if (key == 'key') {
      return '$platform-$expression';
    } else {
      return expression.toString();
    }
  }
}
