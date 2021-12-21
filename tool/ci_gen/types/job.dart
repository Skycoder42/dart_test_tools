// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';
import 'step.dart';
import 'strategy.dart';

part 'job.freezed.dart';
part 'job.g.dart';

class _StepOutputMapConverter
    implements JsonConverter<Map<String, StepOutput>?, Map<String, String>?> {
  const _StepOutputMapConverter();

  @override
  Map<String, StepOutput>? fromJson(Map<String, String>? json) {
    if (json == null) {
      return null;
    }

    return {
      for (final entry in json.entries)
        entry.key: const StepOutputConverter().fromJson(entry.value),
    };
  }

  @override
  Map<String, String>? toJson(Map<String, StepOutput>? outputs) {
    if (outputs == null) {
      return null;
    }

    return {
      for (final entry in outputs.entries)
        entry.key: const StepOutputConverter().toJson(entry.value),
    };
  }
}

@freezed
class Job with _$Job {
  const factory Job({
    required String name,
    @JsonKey(name: 'if', includeIfNull: false)
    @ExpressionConverter()
        Expression? ifExpression,
    @JsonKey(includeIfNull: false) List<String>? needs,
    @JsonKey(includeIfNull: false) Strategy? strategy,
    @JsonKey(includeIfNull: false)
    @_StepOutputMapConverter()
        Map<String, StepOutput>? outputs,
    @JsonKey(name: 'runs-on') required String runsOn,
    required Steps steps,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

typedef Jobs = Map<String, Job>;
