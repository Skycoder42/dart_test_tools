// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

// ignore: unused_import
import 'env.dart';
import 'id.dart';
import 'job.dart';
import 'on.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

@freezed
sealed class Workflow with _$Workflow {
  const factory Workflow({
    required On on,
    @JsonKey(includeIfNull: false) Env? env,
    @JobsConverter() required Jobs jobs,
  }) = _Workflow;

  factory Workflow.fromJson(Map<String, dynamic> json) =>
      _$WorkflowFromJson(json);
}
