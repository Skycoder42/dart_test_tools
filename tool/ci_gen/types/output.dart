// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'id.dart';

part 'output.freezed.dart';
part 'output.g.dart';

@freezed
sealed class Output with _$Output {
  const factory Output({
    @JsonKey(fromJson: Output._fromJson, toJson: Output._toJson)
    required JobIdOutput value,
    @JsonKey(includeIfNull: false) String? description,
  }) = _Output;

  factory Output.fromJson(Map<String, dynamic> json) => _$OutputFromJson(json);

  static String _toJson(JobIdOutput value) =>
      value.workflowExpression.toString();

  static JobIdOutput _fromJson(String json) =>
      throw UnsupportedError('Cannot create an JobIdOutput from json!');
}

typedef Outputs = Map<String, Output>;
