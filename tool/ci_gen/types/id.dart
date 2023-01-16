import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'id.freezed.dart';

abstract class StepId implements Id {
  const factory StepId(String id) = _StepId;
}

abstract class JobId implements Id {
  const factory JobId(String id) = _JobId;
}

@freezed
class Id with _$Id {
  const Id._();

  @Implements<StepId>()
  const factory Id.step(String id) = _StepId;
  @Implements<JobId>()
  const factory Id.job(String id) = _JobId;

  @override
  String toString() => id;

  IdOutput _createOutput(String name) => map(
        step: (stepId) => IdOutput.step(stepId, name),
        job: (jobId) => IdOutput.job(jobId, name),
      );
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
class IdOutput with _$IdOutput {
  const IdOutput._();

  // ignore: unused_element
  const factory IdOutput.step(StepId stepId, String name) = StepIdOutput;
  const factory IdOutput.job(JobId jobId, String name) = JobIdOutput;

  Expression get expression => when(
        step: (id, name) => Expression('steps.$id.outputs.$name'),
        job: (id, name) => Expression('needs.$id.outputs.$name'),
      );

  String bashSetter(String value) => maybeWhen(
        step: (id, name) => 'echo "$name=$value" >> \$GITHUB_OUTPUT',
        orElse: () =>
            throw UnsupportedError('Cannot create a bash setter for $this'),
      );

  Expression get workflowExpression => maybeWhen(
        job: (id, name) => Expression('jobs.$id.outputs.$name'),
        orElse: () => throw UnsupportedError(
          'Cannot create a workflowExpression for $this',
        ),
      );
}

extension IdOutputX on IdOutput {
  Id get id => when(
        step: (stepId, name) => stepId,
        job: (jobId, name) => jobId,
      );
}

extension StepIdOutputX on StepIdOutput {
  StepId get id => stepId;
}

extension JobIdOutputX on JobIdOutput {
  JobId get id => jobId;
}

abstract class _IdConverter<TStep extends Id>
    implements JsonConverter<TStep?, String?> {
  const _IdConverter();

  @override
  String? toJson(TStep? id) => id?.id;
}

class StepIdConverter extends _IdConverter<StepId> {
  const StepIdConverter();

  @override
  StepId? fromJson(String? json) => json != null ? _StepId(json) : null;
}

class JobIdConverter extends _IdConverter<JobId> {
  const JobIdConverter();

  @override
  JobId? fromJson(String? json) => json != null ? _JobId(json) : null;
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
