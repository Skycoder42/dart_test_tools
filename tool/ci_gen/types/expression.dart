import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'expression.freezed.dart';

@freezed
class Expression with _$Expression {
  static const empty = Expression.literal('');

  const Expression._();

  // ignore: sort_unnamed_constructors_first
  const factory Expression(String value) = _Expression;
  @Assert(
    'rawValue is String || rawValue is num || rawValue is bool',
    'Only YAML primitives (string, number, bool) are allowed',
  )
  const factory Expression.literal(dynamic rawValue) = _LiteralExpression;
  const factory Expression.json(Object? jsonValue) = _JsonExpression;
  const factory Expression.fake(String fakeValue) = _FakeExpression;

  String get value => when(
        (value) => value,
        literal: (dynamic rawValue) =>
            rawValue is String ? "'$rawValue'" : rawValue.toString(),
        json: (jsonValue) => json.encode(jsonValue),
        fake: (fakeValue) => fakeValue,
      );

  Expression get not => Expression('!$value');

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
  String toString() => maybeWhen(
        null,
        fake: (fakeValue) => fakeValue,
        orElse: () => '\${{ $value }}',
      );
}

class ExpressionConverter implements JsonConverter<Expression?, String?> {
  const ExpressionConverter();

  @override
  Expression? fromJson(String? json) => json != null ? Expression(json) : null;

  @override
  String? toJson(Expression? expression) => expression?.value;
}
