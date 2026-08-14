import 'package:freezed_annotation/freezed_annotation.dart';

import 'container.dart';
import 'expression.dart';
import 'id.dart';
import 'step.dart';
import 'strategy.dart';

part 'job.freezed.dart';
part 'job.g.dart';

class _StepOutputMapConverter
    implements
        JsonConverter<Map<JobIdOutput, StepIdOutput>?, Map<String, String>?> {
  const new();

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
  const new();

  @override
  Set<JobId>? fromJson(List<String>? json) =>
      json != null ? {...json.map(JobId.fromJson)} : null;

  @override
  List<String>? toJson(Set<JobId>? needs) =>
      needs?.map((id) => id.toJson()).toList();
}

@freezed
sealed class Job with _$Job {
  const factory({
    required String name,
    @JsonKey(includeIfNull: false) @_NeedsConverter() Set<JobId>? needs,
    @JsonKey(name: 'if', includeIfNull: false)
    @ExpressionConverter()
    Expression? ifExpression,
    @JsonKey(includeIfNull: false) String? environment,
    @JsonKey(includeIfNull: false) Map<String, String>? permissions,
    @JsonKey(includeIfNull: false) Strategy? strategy,
    @JsonKey(includeIfNull: false)
    @_StepOutputMapConverter()
    Map<JobIdOutput, StepIdOutput>? outputs,
    @JsonKey(name: 'runs-on') required String runsOn,
    @JsonKey(includeIfNull: false) Container? container,
    required Steps steps,
  }) = _Job;

  factory fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

typedef Jobs = Map<JobId, Job>;

class JobsConverter implements JsonConverter<Jobs, Map<String, dynamic>> {
  const new();

  @override
  Jobs fromJson(Map<String, dynamic> json) => json.map(
    (key, dynamic value) => MapEntry(JobId(key), Job.fromJson(json)),
  );

  @override
  Map<String, dynamic> toJson(Jobs jobs) => jobs.map<String, dynamic>(
    (key, value) => MapEntry<String, dynamic>(key.id, value.toJson()),
  );
}
