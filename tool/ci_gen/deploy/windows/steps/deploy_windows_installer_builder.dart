import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/tools.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';

class DeployWindowsInstallerBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression isDraft;
  final Expression flightId;
  final Expression tenantId;
  final Expression sellerId;
  final Expression clientId;
  final Expression clientSecret;

  const DeployWindowsInstallerBuilder({
    required this.workingDirectory,
    required this.isDraft,
    required this.flightId,
    required this.tenantId,
    required this.clientId,
    required this.clientSecret,
    required this.sellerId,
  });

  @override
  Iterable<Step> build() => [
        const Step.uses(
          name: 'Install msstore cli',
          uses: Tools.microsoftSetupMsstoreCli,
        ),
        ...const CheckoutBuilder().build(),
        Step.uses(
          name: 'Download windows app artifact',
          uses: Tools.actionsDownloadArtifact,
          withArgs: {
            'name': 'app-deployment-windows',
            'path': '$workingDirectory/build/windows/msix',
          },
        ),
        Step.run(
          name: 'Configure msstore cli',
          run: 'msstore reconfigure '
              "--tenantId '$tenantId' "
              "--sellerId '$sellerId' "
              "--clientId '$clientId' "
              "--clientSecret '$clientSecret'",
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Publish MSIX to the Microsoft Store',
          run: 'msstore publish $_draftArgs $_flightIdArgs',
          workingDirectory: workingDirectory.toString(),
        ),
      ];

  Expression get _draftArgs =>
      isDraft.eq(const Expression.literal('true')) &
          const Expression.literal('--noCommit') |
      Expression.empty;

  Expression get _flightIdArgs =>
      flightId.ne(Expression.empty) &
          Functions.format("--flightId ''{0}''", [flightId]) |
      Expression.empty;
}
