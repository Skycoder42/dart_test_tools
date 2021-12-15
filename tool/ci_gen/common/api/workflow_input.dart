import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';

part 'workflow_input.freezed.dart';

typedef WorkflowInputBuilderFn<TParam> = Input Function(TParam param);

@freezed
class WorkflowInput with _$WorkflowInput {
  const WorkflowInput._();

  // ignore: sort_unnamed_constructors_first
  const factory WorkflowInput({
    required String name,
    required Input input,
  }) = _WorkflowInput;

  Expression get expression => Expression('inputs.$name');
}

@freezed
class WorkflowInputBuilder<TParam> with _$WorkflowInputBuilder<TParam> {
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
