import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/id.dart';
import '../../types/output.dart';

part 'workflow_output.freezed.dart';

@freezed
class WorkflowOutput with _$WorkflowOutput {
  const factory WorkflowOutput({
    required String name,
    required String description,
  }) = _WorkflowOutput;
}

class WorkflowOutputContext {
  final _outputs = <String, Output>{};

  void add(WorkflowOutput output, JobIdOutput value) => _outputs.update(
    output.name,
    (_) => throw StateError('Output ${output.name} has already been added'),
    ifAbsent: () => Output(description: output.description, value: value),
  );

  Outputs? createOutputs() =>
      _outputs.isEmpty ? null : UnmodifiableMapView(_outputs);
}
