import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/input.dart';

part 'workflow_input.freezed.dart';

typedef WorkflowInputBuilderFn<TParam> = Input Function(TParam param);

abstract class IWorkflowInput {
  IWorkflowInput._();

  String get name;
}

extension IWorkflowInputX on IWorkflowInput {
  String get expression => 'inputs.$name';
}

@freezed
class WorkflowInput with _$WorkflowInput implements IWorkflowInput {
  const WorkflowInput._();

  // ignore: sort_unnamed_constructors_first
  const factory WorkflowInput({
    required String name,
    required Input input,
  }) = _WorkflowInput;
}

@freezed
class WorkflowInputBuilder<TParam>
    with _$WorkflowInputBuilder<TParam>
    implements IWorkflowInput {
  const WorkflowInputBuilder._();

  // ignore: sort_unnamed_constructors_first
  const factory WorkflowInputBuilder({
    required String name,
    required WorkflowInputBuilderFn<TParam> builder,
  }) = _WorkflowInputBuilder<TParam>;

  WorkflowInput call(TParam param) => WorkflowInput(
        name: name,
        input: builder(param),
      );
}
