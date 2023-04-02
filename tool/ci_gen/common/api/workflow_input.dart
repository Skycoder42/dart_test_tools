import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';

part 'workflow_input.freezed.dart';

typedef InputBuilderFn<TParam> = Input Function(TParam param);

@freezed
class WorkflowInput with _$WorkflowInput {
  const WorkflowInput._();

  // ignore: sort_unnamed_constructors_first
  const factory WorkflowInput({
    required String name,
    required Input input,
  }) = _WorkflowInput;
}

class WorkflowInputContext {
  final _inputs = <WorkflowInput>{};

  Expression call(WorkflowInput input) {
    _inputs.add(input);
    return Expression('inputs.${input.name}');
  }

  Map<String, Input> createInputs() => {
        for (final input in _inputs) input.name: input.input,
      };
}
