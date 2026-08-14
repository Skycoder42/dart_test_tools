import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'env.freezed.dart';

@freezed
sealed class Env with _$Env {
  const factory(Map<String, String> env) = _Env;

  const factory expression(Expression expression) = _EnvExpression;

  const new _();

  // ignore: prefer_expression_function_bodies for freezed
  factory fromJson(Map<String, dynamic> json) {
    return Env(json as Map<String, String>);
  }

  dynamic toJson() => switch (this) {
    _Env(:final env) => env,
    _EnvExpression(:final expression) => expression.toString(),
  };
}
