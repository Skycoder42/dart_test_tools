import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../common/secrets.dart';
import '../../../types/step.dart';

base mixin WithGpgKeyConfig on JobConfig {
  bool get requireGpgKey;

  late final gpgKey = secretContext(WorkflowSecrets.gpgKey(requireGpgKey));
  late final gpgKeyId = secretContext(WorkflowSecrets.gpgKeyId(requireGpgKey));
}

class const WithGpgKey({
  required final WithGpgKeyConfig config,
  required final Steps steps,
}) implements StepBuilder {
  @override
  Iterable<Step> build() => [
    Step.run(
      name: 'Import GPG key',
      run: "echo '${config.gpgKey}' | gpg --import",
    ),
    ...steps,
    Step.run(
      name: 'Delete GPG key',
      ifExpression: Functions.always,
      continueOnError: true,
      run: "gpg --batch --yes --delete-secret-keys '${config.gpgKeyId}'",
    ),
  ];
}
