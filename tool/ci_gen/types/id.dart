import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'id.freezed.dart';

sealed class Id {
  final String id;

  const new(this.id);

  const factory step(String id) = StepId;

  const factory job(String id) = JobId;

  IdOutput output(String name);

  String toJson() => id;

  @override
  String toString() => id;
}

class StepId extends Id {
  const new(super.id);

  const new fromJson(super.id);

  @override
  StepIdOutput output(String name) => StepIdOutput(this, name);
}

class JobId extends Id {
  const new(super.id);

  const new fromJson(super.id);

  @override
  JobIdOutput output(String name) => JobIdOutput(this, name);
}

@freezed
sealed class IdOutput with _$IdOutput {
  const new _();

  const factory step(StepId stepId, String name) = StepIdOutput;
  const factory job(JobId jobId, String name) = JobIdOutput;

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

  String pwshSetter(String value, {bool isCommand = false}) => switch (this) {
    StepIdOutput(:final name) when isCommand =>
      'Add-Content -Path \$Env:GITHUB_OUTPUT -Value "$name=\$($value)"',
    StepIdOutput(:final name) when !isCommand =>
      'Add-Content -Path \$Env:GITHUB_OUTPUT -Value "$name=$value"',
    _ => throw UnsupportedError('Cannot create a pwsh setter for $this'),
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
  const new();

  @override
  IdOutput fromJson(String json) {
    throw UnsupportedError('Cannot create a StepOutput from json!');
  }

  @override
  String toJson(IdOutput output) => output.expression.toString();
}
