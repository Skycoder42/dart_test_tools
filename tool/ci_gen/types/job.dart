// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';
import 'id.dart';
import 'step.dart';
import 'strategy.dart';

part 'job.freezed.dart';
part 'job.g.dart';

class _StepOutputMapConverter
    implements
        JsonConverter<Map<JobIdOutput, StepIdOutput>?, Map<String, String>?> {
  const _StepOutputMapConverter();

  @override
  Map<JobIdOutput, StepIdOutput>? fromJson(Map<String, String>? json) {
    if (json == null) {
      return null;
    }

    throw UnsupportedError('Cannot create a StepOutput map from json!');
  }

  @override
  Map<String, String>? toJson(Map<JobIdOutput, StepIdOutput>? outputs) {
    if (outputs == null) {
      return null;
    }

    return {
      for (final entry in outputs.entries)
        entry.key.name: const IdOutputConverter().toJson(entry.value),
    };
  }
}

class _NeedsConverter implements JsonConverter<Set<JobId>?, List<String>?> {
  const _NeedsConverter();

  @override
  Set<JobId>? fromJson(List<String>? json) => json != null
      ? {...json.map((j) => const JobIdConverter().fromJson(j)!)}
      : null;

  @override
  List<String>? toJson(Set<JobId>? needs) =>
      needs?.map((id) => const JobIdConverter().toJson(id)!).toList();
}

@freezed
class Job with _$Job {
  const factory Job({
    required String name,
    @JsonKey(includeIfNull: false) @_NeedsConverter() Set<JobId>? needs,
    @JsonKey(name: 'if', includeIfNull: false)
    @ExpressionConverter()
        Expression? ifExpression,
    @JsonKey(includeIfNull: false) Map<String, String>? permissions,
    @JsonKey(includeIfNull: false) Strategy? strategy,
    @JsonKey(includeIfNull: false)
    @_StepOutputMapConverter()
        Map<JobIdOutput, StepIdOutput>? outputs,
    @JsonKey(name: 'runs-on') required String runsOn,
    @JsonKey(includeIfNull: false) String? container,
    required Steps steps,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

typedef Jobs = Map<JobId, Job>;

class JobsConverter implements JsonConverter<Jobs, Map<String, dynamic>> {
  const JobsConverter();

  @override
  Jobs fromJson(Map<String, dynamic> json) => json
      .map((key, dynamic value) => MapEntry(JobId(key), Job.fromJson(json)));

  @override
  Map<String, dynamic> toJson(Jobs jobs) => jobs.map<String, dynamic>(
        (key, value) => MapEntry<String, dynamic>(key.id, value.toJson()),
      );
}
