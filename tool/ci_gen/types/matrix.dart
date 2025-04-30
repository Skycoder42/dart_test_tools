import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'matrix.freezed.dart';

@freezed
sealed class Matrix with _$Matrix {
  const factory Matrix(
    Map<String, dynamic> matrix, {
    List<Map<String, dynamic>>? include,
    List<Map<String, dynamic>>? exclude,
  }) = _Matrix;

  const factory Matrix.expression(Expression expression) = _MatrixExpression;

  const Matrix._();

  factory Matrix.fromJson(Map<String, dynamic> json) {
    final include = _extractFilter(json, 'include');
    final exclude = _extractFilter(json, 'exclude');
    return Matrix(
      json as Map<String, List<dynamic>>,
      include: include,
      exclude: exclude,
    );
  }

  dynamic toJson() => switch (this) {
    _Matrix(:final matrix, :final include, :final exclude) => {
      ...matrix,
      if (include != null) 'include': include,
      if (exclude != null) 'exclude': exclude,
    },
    _MatrixExpression(:final expression) => expression.toString(),
  };

  static List<Map<String, dynamic>>? _extractFilter(
    Map<String, dynamic> json,
    String key,
  ) {
    if (json.containsKey(key)) {
      return json.remove(key) as List<Map<String, dynamic>>;
    } else {
      return null;
    }
  }
}
