import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';

part 'workflow_input.freezed.dart';

typedef InputBuilderFn<TParam> = Input Function(TParam param);

@freezed
sealed class WorkflowInput with _$WorkflowInput {
  const factory WorkflowInput({required String name, required Input input}) =
      _WorkflowInput;

  const WorkflowInput._();
}

class WorkflowInputContext {
  final _inputs = <WorkflowInput>{};

  Expression call(WorkflowInput input) {
    _inputs.add(input);
    return Expression('inputs.${input.name}');
  }

  Inputs? createInputs() => _inputs.isEmpty
      ? null
      : {for (final input in _inputs) input.name: input.input};
}
