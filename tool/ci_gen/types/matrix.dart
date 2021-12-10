import 'package:freezed_annotation/freezed_annotation.dart';

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

  factory Matrix.fromJson(Map<String, dynamic> json) {
    final include = _extractFilter(json, 'include');
    final exclude = _extractFilter(json, 'exclude');
    return Matrix(
      json as Map<String, List<dynamic>>,
      include: include,
      exclude: exclude,
    );
  }

  Map<String, dynamic> toJson() => {
        ...matrix,
        if (include != null) 'include': include,
        if (exclude != null) 'exclude': exclude,
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
