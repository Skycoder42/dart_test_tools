import 'package:freezed_annotation/freezed_annotation.dart';

import 'env.dart';
import 'job.dart';
import 'on.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

@freezed
sealed class Workflow with _$Workflow {
  const factory({
    required On on,
    @JsonKey(includeIfNull: false) Env? env,
    @JobsConverter() required Jobs jobs,
  }) = _Workflow;

  factory fromJson(Map<String, dynamic> json) => _$WorkflowFromJson(json);
}
