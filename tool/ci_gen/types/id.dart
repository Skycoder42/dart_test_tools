import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'id.freezed.dart';

sealed class Id {
  final String id;

  const Id(this.id);

  const factory Id.step(String id) = StepId;

  const factory Id.job(String id) = JobId;

  IdOutput output(String name);

  String toJson() => id;

  @override
  String toString() => id;
}

class StepId extends Id {
  const StepId(super.id);

  const StepId.fromJson(super.id);

  @override
  StepIdOutput output(String name) => StepIdOutput(this, name);
}

class JobId extends Id {
  const JobId(super.id);

  const JobId.fromJson(super.id);

  @override
  JobIdOutput output(String name) => JobIdOutput(this, name);
}

extension StepIdX on StepId {}

@freezed
sealed class IdOutput with _$IdOutput {
  const IdOutput._();

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
        StepIdOutput(:final name) =>
          '''
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

class IdOutputConverter implements JsonConverter<IdOutput, String> {
  const IdOutputConverter();

  @override
  IdOutput fromJson(String json) {
    throw UnsupportedError('Cannot create a StepOutput from json!');
  }

  @override
  String toJson(IdOutput output) => output.expression.toString();
}
