// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'input.dart';
import 'output.dart';
import 'secret.dart';

part 'workflow_call.freezed.dart';
part 'workflow_call.g.dart';

@freezed
sealed class WorkflowCall with _$WorkflowCall {
  const factory WorkflowCall({
    @JsonKey(includeIfNull: false) Inputs? inputs,
    @JsonKey(includeIfNull: false) Outputs? outputs,
    @JsonKey(includeIfNull: false) Secrets? secrets,
  }) = _WorkflowCall;

  factory WorkflowCall.fromJson(Map<String, dynamic> json) =>
      _$WorkflowCallFromJson(json);
}
