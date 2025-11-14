// ignore_for_file: invalid_annotation_target for freezed

import 'package:freezed_annotation/freezed_annotation.dart';

import 'action_runs.dart';
import 'input.dart';
import 'output.dart';

part 'action.freezed.dart';
part 'action.g.dart';

@freezed
sealed class Action with _$Action {
  const factory Action({
    required String name,
    required String description,
    @JsonKey(includeIfNull: false) Inputs? inputs,
    @JsonKey(includeIfNull: false) Outputs? outputs,
    required ActionsRuns runs,
  }) = _Action;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);
}
