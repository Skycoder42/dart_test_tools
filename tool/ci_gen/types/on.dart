// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'workflow_call.dart';

part 'on.freezed.dart';
part 'on.g.dart';

@freezed
sealed class On with _$On {
  const factory On({
    @JsonKey(name: 'workflow_call') required WorkflowCall workflowCall,
  }) = _On;

  factory On.fromJson(Map<String, dynamic> json) => _$OnFromJson(json);
}
