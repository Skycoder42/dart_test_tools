import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';

base mixin WithGpgKeyConfig on JobConfig {
  late Expression gpgKey;
  late Expression gpgKeyId;
}

class WithGpgKey implements StepBuilder {
  final WithGpgKeyConfig config;
  final Steps steps;

  const WithGpgKey({
    required this.config,
    required this.steps,
  });

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
