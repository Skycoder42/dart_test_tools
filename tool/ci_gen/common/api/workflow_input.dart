import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import 'expression_builder.dart';

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

@freezed
class WorkflowInputBuilder<TParam> with _$WorkflowInputBuilder<TParam> {
  const WorkflowInputBuilder._();

  // ignore: sort_unnamed_constructors_first
  const factory WorkflowInputBuilder({
    required String name,
    required InputBuilderFn<TParam> builder,
  }) = _WorkflowInputBuilder<TParam>;

  WorkflowInput call(TParam param) => WorkflowInput(
        name: name,
        input: builder(param),
      );
}

class WorkflowInputContext {
  final _inputs = <WorkflowInput>{};

  Expression call(WorkflowInput input) {
    _inputs.add(input);
    return Expression('inputs.${input.name}');
  }

  ExpressionBuilderFn<TParam> builder<TParam>(
    WorkflowInputBuilder<TParam> builder,
  ) =>
      (param) => call(builder(param));

  Map<String, Input> createInputs() => {
        for (final input in _inputs) input.name: input.input,
      };
}
