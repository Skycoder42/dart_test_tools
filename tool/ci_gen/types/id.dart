import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'id.freezed.dart';

// ignore: avoid_implementing_value_types because this is a workaround as otherwise the workflow cannot be generated
abstract interface class StepId implements Id {
  const factory StepId(String id) = _StepId;
}

// ignore: avoid_implementing_value_types because this is a workaround as otherwise the workflow cannot be generated
abstract interface class JobId implements Id {
  const factory JobId(String id) = _JobId;
}

@freezed
sealed class Id with _$Id {
  @Implements<StepId>()
  const factory Id.step(String id) = _StepId;

  @Implements<JobId>()
  const factory Id.job(String id) = _JobId;

  const Id._();

  @override
  String toString() => id;

  IdOutput _createOutput(String name) => switch (this) {
    final StepId stepId => IdOutput.step(stepId, name),
    final JobId jobId => IdOutput.job(jobId, name),
  };
}

extension IdX on Id {
  IdOutput output(String name) => _createOutput(name);
}

extension StepIdX on StepId {
  StepIdOutput output(String name) => _createOutput(name) as StepIdOutput;
}

extension JobIdX on JobId {
  JobIdOutput output(String name) => _createOutput(name) as JobIdOutput;
}

@freezed
sealed class IdOutput with _$IdOutput {
  const IdOutput._();

  // ignore: unused_element
  const factory IdOutput.step(StepId stepId, String name) = StepIdOutput;
  const factory IdOutput.job(JobId jobId, String name) = JobIdOutput;

  Expression get expression => switch (this) {
    StepIdOutput(:final stepId, :final name) => Expression(
      'steps.$stepId.outputs.$name',
    ),
    JobIdOutput(:final jobId, :final name) => Expression(
      'needs.$jobId.outputs.$name',
    ),
  };

  String bashSetter(String value, {bool isCommand = false}) => switch (this) {
    StepIdOutput(:final name) when isCommand =>
      'echo "$name=\$($value)" >> \$GITHUB_OUTPUT',
    StepIdOutput(:final name) when !isCommand =>
      'echo "$name=$value" >> \$GITHUB_OUTPUT',
    _ => throw UnsupportedError('Cannot create a bash setter for $this'),
  };

  String bashSetterMultiLine(String value, {bool isCommand = false}) =>
      switch (this) {
        StepIdOutput(:final name) => '''
echo "$name<<EOF" >> \$GITHUB_OUTPUT
${isCommand ? value : 'echo "$value"'} >> \$GITHUB_OUTPUT
echo "EOF" >> \$GITHUB_OUTPUT
''',
        _ => throw UnsupportedError('Cannot create a bash setter for $this'),
      };

  Expression get workflowExpression => switch (this) {
    JobIdOutput(:final jobId, :final name) => Expression(
      'jobs.$jobId.outputs.$name',
    ),
    _ => throw UnsupportedError('Cannot create a workflowExpression for $this'),
  };
}

extension IdOutputX on IdOutput {
  Id get id => switch (this) {
    StepIdOutput(:final stepId) => stepId,
    JobIdOutput(:final jobId) => jobId,
  };
}

extension StepIdOutputX on StepIdOutput {
  StepId get id => stepId;
}

extension JobIdOutputX on JobIdOutput {
  JobId get id => jobId;
}

abstract base class _IdConverter<TStep extends Id>
    implements JsonConverter<TStep?, String?> {
  const _IdConverter();

  @override
  String? toJson(TStep? id) => id?.id;
}

final class StepIdConverter extends _IdConverter<StepId> {
  const StepIdConverter();

  @override
  StepId? fromJson(String? json) => json != null ? StepId(json) : null;
}

final class JobIdConverter extends _IdConverter<JobId> {
  const JobIdConverter();

  @override
  JobId? fromJson(String? json) => json != null ? JobId(json) : null;
}

class IdOutputConverter implements JsonConverter<IdOutput, String> {
  const IdOutputConverter();

  @override
  IdOutput fromJson(String json) {
    throw UnsupportedError('Cannot create a StepOutput from json!');
  }

  @override
  String toJson(IdOutput output) => output.expression.toString();
}
