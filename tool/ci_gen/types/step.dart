// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'step.freezed.dart';
part 'step.g.dart';

@freezed
class StepId with _$StepId {
  const StepId._();

  // ignore: sort_unnamed_constructors_first
  const factory StepId(String id) = _StepId;

  @override
  String toString() => id;

  StepOutput output(String name) => StepOutput._fromStepId(this, name);
}

class StepIdConverter implements JsonConverter<StepId?, String?> {
  const StepIdConverter();

  @override
  StepId? fromJson(String? json) => json != null ? StepId(json) : null;

  @override
  String? toJson(StepId? stepId) => stepId?.id;
}

@freezed
class StepOutput with _$StepOutput {
  const StepOutput._();

  // ignore: unused_element
  const factory StepOutput._fromStepId(StepId stepId, String name) =
      _StepOutput;

  Expression get expression => Expression('steps.${stepId.id}.outputs.$name');

  String bashSetter(String value) => 'echo "::set-output name=$name::$value"';
}

class StepOutputConverter implements JsonConverter<StepOutput, String> {
  const StepOutputConverter();

  @override
  StepOutput fromJson(String json) {
    throw UnsupportedError('Cannot create a StepOutput from json!');
  }

  @override
  String toJson(StepOutput stepOutput) => stepOutput.expression.toString();
}

@freezed
class Step with _$Step {
  const Step._();

  const factory Step.run({
    @JsonKey(includeIfNull: false) @StepIdConverter() StepId? id,
    required String name,
    @JsonKey(name: 'if', includeIfNull: false)
    @ExpressionConverter()
        Expression? ifExpression,
    @JsonKey(includeIfNull: false) Map<String, String>? env,
    required String run,
    @JsonKey(name: 'working-directory', includeIfNull: false)
        String? workingDirectory,
    @JsonKey(includeIfNull: false) String? shell,
  }) = _RunStep;

  const factory Step.uses({
    @JsonKey(includeIfNull: false) @StepIdConverter() StepId? id,
    required String name,
    @JsonKey(name: 'if', includeIfNull: false)
    @ExpressionConverter()
        Expression? ifExpression,
    @JsonKey(includeIfNull: false) Map<String, String>? env,
    required String uses,
    @JsonKey(name: 'with', includeIfNull: false) Map<String, dynamic>? withArgs,
  }) = _UsesStep;

  factory Step.fromJson(Map<String, dynamic> json) => _$StepFromJson(json);
}

typedef Steps = List<Step>;
