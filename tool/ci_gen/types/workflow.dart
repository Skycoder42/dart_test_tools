import 'package:freezed_annotation/freezed_annotation.dart';

import 'job.dart';
import 'on.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

@freezed
class Workflow with _$Workflow {
  const factory Workflow({
    required On on,
    required Jobs jobs,
  }) = _Workflow;

  factory Workflow.fromJson(Map<String, dynamic> json) =>
      _$WorkflowFromJson(json);
}
