import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'expression.freezed.dart';

@freezed
class Expression with _$Expression {
  static const empty = Expression.literal('');

  static const always = Expression('always()');

  const Expression._();

  // ignore: sort_unnamed_constructors_first
  const factory Expression(String value) = _Expression;
  @Assert(
    // ignore: lines_longer_than_80_chars
    'rawValue is String || rawValue is num || rawValue is bool || rawValue is Null',
    'Only YAML primitives (string, number, bool, null) are allowed',
  )
  const factory Expression.literal(dynamic rawValue) = _LiteralExpression;
  const factory Expression.json(Object? jsonValue) = _JsonExpression;
  const factory Expression.fake(String fakeValue) = _FakeExpression;

  dynamic get value => when<dynamic>(
        (value) => value,
        literal: (dynamic rawValue) =>
            rawValue is String ? "'$rawValue'" : rawValue,
        json: (jsonValue) => json.encode(jsonValue),
        fake: (fakeValue) => fakeValue,
      );

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
  String toString() => maybeWhen(
        null,
        fake: (fakeValue) => fakeValue,
        orElse: () => '\${{ $value }}',
      );
}

class ExpressionConverter implements JsonConverter<Expression?, dynamic> {
  const ExpressionConverter();

  @override
  Expression? fromJson(dynamic json) =>
      json != null ? Expression(json as String) : null;

  @override
  dynamic toJson(Expression? expression) => expression?.value;
}
