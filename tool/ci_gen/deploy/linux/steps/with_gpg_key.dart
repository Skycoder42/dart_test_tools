import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';

class WithGpgKey implements StepBuilder {
  final Expression gpgKey;
  final Expression gpgKeyId;
  final Steps steps;

  const WithGpgKey({
    required this.gpgKey,
    required this.gpgKeyId,
    required this.steps,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Import GPG key',
          run: "echo '$gpgKey' | gpg --import",
        ),
        ...steps,
        Step.run(
          name: 'Delete GPG key',
          ifExpression: Functions.always,
          continueOnError: true,
          run: "gpg --batch --yes --delete-secret-keys '$gpgKeyId'",
        ),
      ];
}
