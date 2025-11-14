import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'env.freezed.dart';

@freezed
sealed class Env with _$Env {
  const factory Env(Map<String, String> env) = _Env;

  const factory Env.expression(Expression expression) = _EnvExpression;

  const Env._();

  // ignore: prefer_expression_function_bodies for freezed
  factory Env.fromJson(Map<String, dynamic> json) {
    return Env(json as Map<String, String>);
  }

  dynamic toJson() => switch (this) {
    _Env(:final env) => env,
    _EnvExpression(:final expression) => expression.toString(),
  };
}
