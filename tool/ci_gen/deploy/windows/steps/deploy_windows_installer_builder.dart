import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/contexts.dart';
import '../../../common/inputs.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/tools.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';

base mixin DeployWindowsInstallerConfig on JobConfig, WorkingDirectoryConfig {
  late final isDraft = inputContext(WorkflowInputs.isDraft);
  late final flightId = inputContext(WorkflowInputs.flightId);
  late final tenantId = secretContext(WorkflowSecrets.tenantId);
  late final sellerId = secretContext(WorkflowSecrets.sellerId);
  late final clientId = secretContext(WorkflowSecrets.clientId);
  late final clientSecret = secretContext(WorkflowSecrets.clientSecret);
}

class DeployWindowsInstallerBuilder implements StepBuilder {
  final DeployWindowsInstallerConfig config;

  const DeployWindowsInstallerBuilder({
    required this.config,
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
            'path': '${config.workingDirectory}/build/windows/msix',
          },
        ),
        Step.run(
          name: 'Configure msstore cli',
          run: 'msstore reconfigure '
              "--tenantId '${config.tenantId}' "
              "--sellerId '${config.sellerId}' "
              "--clientId '${config.clientId}' "
              "--clientSecret '${config.clientSecret}'",
          workingDirectory: config.workingDirectory.toString(),
        ),
        Step.run(
          name: 'Publish MSIX to the Microsoft Store',
          run: 'msstore publish $_draftArgs $_flightIdArgs',
          workingDirectory: config.workingDirectory.toString(),
        ),
      ];

  Expression get _draftArgs =>
      config.isDraft.eq(const Expression.literal('true')) &
          const Expression.literal('--noCommit') |
      Expression.empty;

  Expression get _flightIdArgs =>
      config.flightId.ne(Expression.empty) &
          Functions.format("--flightId ''{0}''", [config.flightId]) |
      Expression.empty;
}
