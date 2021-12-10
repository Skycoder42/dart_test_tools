// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'step.dart';
import 'strategy.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String name,
    @JsonKey(name: 'if', includeIfNull: false) String? ifExpression,
    @JsonKey(includeIfNull: false) List<String>? needs,
    @JsonKey(includeIfNull: false) Strategy? strategy,
    @JsonKey(name: 'runs-on') required String runsOn,
    required Steps steps,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

typedef Jobs = Map<String, Job>;
