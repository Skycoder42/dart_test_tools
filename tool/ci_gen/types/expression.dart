import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'expression.freezed.dart';

@freezed
sealed class Expression with _$Expression {
  static const empty = Expression.literal('');

  const factory Expression(String value) = _Expression;

  @Assert(
    // ignore: lines_longer_than_80_chars
    'rawValue is String || rawValue is num || rawValue is bool || rawValue is Null',
    'Only YAML primitives (string, number, bool, null) are allowed',
  )
  const factory Expression.literal(dynamic rawValue) = _LiteralExpression;

  const factory Expression.json(Object? jsonValue) = _JsonExpression;

  const factory Expression.fake(String fakeValue) = _FakeExpression;

  const Expression._();

  dynamic get value => switch (this) {
    _Expression(:final value) => value,
    _LiteralExpression(:final String rawValue) => "'$rawValue'",
    _LiteralExpression(:final rawValue) => rawValue,
    _JsonExpression(:final jsonValue) => json.encode(jsonValue),
    _FakeExpression(:final fakeValue) => fakeValue,
  };

  Expression property(String name) => Expression('$value.$name');

  Expression get parenthesized => Expression('($value)');

  Expression get not => Expression('!$value');

  Expression call(List<Expression> arguments) => Expression(
    '$value(${arguments.map<dynamic>((e) => e.value).join(', ')})',
  );

  Expression operator <(Expression other) =>
      Expression('$value < ${other.value}');

  Expression operator <=(Expression other) =>
      Expression('$value <= ${other.value}');

  Expression operator >(Expression other) =>
      Expression('$value > ${other.value}');

  Expression operator >=(Expression other) =>
      Expression('$value >= ${other.value}');

  Expression eq(Expression other) => Expression('$value == ${other.value}');

  Expression ne(Expression other) => Expression('$value != ${other.value}');

  Expression operator &(Expression? other) =>
      other != null ? Expression('$value && ${other.value}') : this;

  Expression operator |(Expression? other) =>
      other != null ? Expression('$value || ${other.value}') : this;

  @override
  String toString() => switch (this) {
    _FakeExpression(:final fakeValue) => fakeValue,
    _ => '\${{ $value }}',
  };
}

@freezed
sealed class ExpressionOrValue with _$ExpressionOrValue {
  const factory ExpressionOrValue.expression(Expression expression) =
      ExpressionOrValueExpression;

  const factory ExpressionOrValue.value(dynamic value) = ExpressionOrValueValue;

  const ExpressionOrValue._();

  bool get isExpression => this is ExpressionOrValueExpression;

  bool get isValue => this is ExpressionOrValueValue;

  T rawValueOr<T>(T defaultValue) => switch (this) {
    ExpressionOrValueExpression() => defaultValue,
    ExpressionOrValueValue(:final value) => value as T,
  };

  dynamic get asValue => switch (this) {
    ExpressionOrValueExpression(:final expression) => expression.toString(),
    ExpressionOrValueValue(:final value) => value,
  };

  Expression get asExpression => switch (this) {
    ExpressionOrValueExpression(:final expression) => expression,
    ExpressionOrValueValue(:final value) => Expression.literal(value),
  };

  @override
  String toString() => asValue.toString();
}

class ExpressionConverter implements JsonConverter<Expression?, dynamic> {
  const ExpressionConverter();

  @override
  Expression? fromJson(dynamic json) =>
      json != null ? Expression(json as String) : null;

  @override
  dynamic toJson(Expression? expression) => expression?.value;
}
