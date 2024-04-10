// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'env.dart';
import 'expression.dart';
import 'id.dart';

part 'step.freezed.dart';
part 'step.g.dart';

@freezed
class Step with _$Step {
  const Step._();

  const factory Step.run({
    @JsonKey(includeIfNull: false) @StepIdConverter() StepId? id,
    required String name,
    @JsonKey(name: 'if', includeIfNull: false)
    @ExpressionConverter()
    Expression? ifExpression,
    @JsonKey(name: 'continue-on-error', includeIfNull: false)
    bool? continueOnError,
    @JsonKey(includeIfNull: false) Env? env,
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
    @JsonKey(name: 'continue-on-error', includeIfNull: false)
    bool? continueOnError,
    @JsonKey(includeIfNull: false) Map<String, String>? env,
    required String uses,
    @JsonKey(name: 'with', includeIfNull: false) Map<String, dynamic>? withArgs,
  }) = _UsesStep;

  factory Step.fromJson(Map<String, dynamic> json) => _$StepFromJson(json);
}

typedef Steps = List<Step>;
