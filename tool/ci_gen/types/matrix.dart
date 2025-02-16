import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'matrix.freezed.dart';

@freezed
class Matrix with _$Matrix {
  const Matrix._();

  // ignore: sort_unnamed_constructors_first
  const factory Matrix(
    Map<String, List<dynamic>> matrix, {
    List<Map<String, dynamic>>? include,
    List<Map<String, dynamic>>? exclude,
  }) = _Matrix;

  const factory Matrix.expression(Expression expression) = _MatrixExpression;

  factory Matrix.fromJson(Map<String, dynamic> json) {
    final include = _extractFilter(json, 'include');
    final exclude = _extractFilter(json, 'exclude');
    return Matrix(
      json as Map<String, List<dynamic>>,
      include: include,
      exclude: exclude,
    );
  }

  dynamic toJson() => when(
    (matrix, include, exclude) => {
      ...matrix,
      if (include != null) 'include': include,
      if (exclude != null) 'exclude': exclude,
    },
    expression: (expression) => expression.toString(),
  );

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
