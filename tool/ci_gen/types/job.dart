// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';
import 'id.dart';
import 'step.dart';
import 'strategy.dart';

part 'job.freezed.dart';
part 'job.g.dart';

class _StepOutputMapConverter
    implements JsonConverter<Map<IdOutput, IdOutput>?, Map<String, String>?> {
  const _StepOutputMapConverter();

  @override
  Map<IdOutput, IdOutput>? fromJson(Map<String, String>? json) {
    if (json == null) {
      return null;
    }

    throw UnsupportedError('Cannot create a StepOutput map from json!');
  }

  @override
  Map<String, String>? toJson(Map<IdOutput, IdOutput>? outputs) {
    if (outputs == null) {
      return null;
    }

    return {
      for (final entry in outputs.entries)
        entry.key.name: const IdOutputConverter().toJson(entry.value),
    };
  }
}

class _NeedsConverter implements JsonConverter<List<JobId>?, List<String>?> {
  const _NeedsConverter();

  @override
  List<JobId>? fromJson(List<String>? json) =>
      json?.map((j) => const JobIdConverter().fromJson(j)!).toList();

  @override
  List<String>? toJson(List<JobId>? needs) =>
      needs?.map((id) => const JobIdConverter().toJson(id)!).toList();
}

@freezed
class Job with _$Job {
  const factory Job({
    required String name,
    @JsonKey(name: 'if', includeIfNull: false)
    @ExpressionConverter()
        Expression? ifExpression,
    @JsonKey(includeIfNull: false) @_NeedsConverter() List<JobId>? needs,
    @JsonKey(includeIfNull: false) Strategy? strategy,
    @JsonKey(includeIfNull: false)
    @_StepOutputMapConverter()
        Map<IdOutput, IdOutput>? outputs,
    @JsonKey(name: 'runs-on') required String runsOn,
    required Steps steps,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

typedef Jobs = Map<JobId, Job>;

class JobsConverter implements JsonConverter<Jobs, Map<String, dynamic>> {
  const JobsConverter();

  @override
  Jobs fromJson(Map<String, dynamic> json) =>
      json.map((key, value) => MapEntry(JobId(key), Job.fromJson(json)));

  @override
  Map<String, dynamic> toJson(Jobs jobs) =>
      jobs.map((key, value) => MapEntry(key.id, value.toJson()));
}
