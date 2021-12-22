import 'package:freezed_annotation/freezed_annotation.dart';

import 'expression.dart';

part 'id.freezed.dart';

@freezed
class Id with _$Id {
  const Id._();

  const factory Id.step(String id) = StepId;
  const factory Id.job(String id) = JobId;

  @override
  String toString() => id;

  IdOutput output(String name) => IdOutput._fromStepId(this, name);
}

@freezed
class IdOutput with _$IdOutput {
  const IdOutput._();

  // ignore: unused_element
  const factory IdOutput._fromStepId(Id id, String name) = _IdOutput;

  Expression get expression => id.when(
        step: (id) => Expression('steps.$id.outputs.$name'),
        job: (id) => Expression('needs.$id.outputs.$name'),
      );

  String bashSetter(String value) => id.maybeMap(
        step: (_) => 'echo "::set-output name=$name::$value"',
        orElse: () =>
            throw UnsupportedError('Cannot create a bash setter for $id'),
      );
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
  StepId? fromJson(String? json) => json != null ? StepId(json) : null;
}

class JobIdConverter extends _IdConverter<JobId> {
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
