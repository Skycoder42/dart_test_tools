import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/secret.dart';

part 'workflow_secret.freezed.dart';

typedef InputBuilderFn<TParam> = Input Function(TParam param);

@freezed
class WorkflowSecret with _$WorkflowSecret {
  const WorkflowSecret._();

  // ignore: sort_unnamed_constructors_first
  const factory WorkflowSecret({
    required String name,
    required Secret secret,
  }) = _WorkflowSecret;
}

class WorkflowSecretContext {
  final _secrets = <WorkflowSecret>{};

  Expression call(WorkflowSecret secret) {
    _secrets.add(secret);
    return Expression('secrets.${secret.name}');
  }

  Secrets? createSecrets() => _secrets.isEmpty
      ? null
      : {for (final secret in _secrets) secret.name: secret.secret};
}
