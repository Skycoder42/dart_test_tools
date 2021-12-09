// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'output.freezed.dart';
part 'output.g.dart';

enum Type {
  boolean,
  number,
  string,
}

@freezed
class Output with _$Output {
  const factory Output({
    required String value,
    @JsonKey(includeIfNull: false) String? description,
  }) = _Output;

  factory Output.fromJson(Map<String, dynamic> json) => _$OutputFromJson(json);
}

typedef Outputs = Map<String, Output>;
