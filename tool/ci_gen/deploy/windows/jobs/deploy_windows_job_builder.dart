import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/environments.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/secrets.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../../steps/validate_inputs_builder.dart';
import '../steps/deploy_windows_installer_builder.dart';

final class DeployWindowsJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  final JobIdOutput releaseCreated;
  final Expression enabledPlatforms;
  @override
  final Expression flutterSdkChannel;
  final Expression workingDirectory;
  final Expression isDraft;
  final Expression flightId;
  final Expression tenantId;
  final Expression sellerId;
  final Expression clientId;
  final Expression clientSecret;

  const DeployWindowsJobBuilder({
    required this.releaseCreated,
    required this.enabledPlatforms,
    required this.flutterSdkChannel,
    required this.workingDirectory,
    required this.isDraft,
    required this.flightId,
    required this.tenantId,
    required this.sellerId,
    required this.clientId,
    required this.clientSecret,
  });

  @override
  JobId get id => const JobId('deploy_windows');

  @override
  Job build() => Job(
        name: 'Publish MSIX installer to Microsoft Store',
        runsOn: RunsOn.windowsLatest.id,
        needs: {releaseCreated.jobId},
        ifExpression:
            releaseCreated.expression.eq(const Expression.literal('true')) &
                EnabledPlatforms.check(
                  enabledPlatforms,
                  Expression.literal(FlutterPlatform.windows.platform),
                ),
        environment: Environments.msstore,
        steps: [
          ...ValidateInputsBuilder({
            WorkflowSecrets.tenantId.name: tenantId,
            WorkflowSecrets.sellerId.name: sellerId,
            WorkflowSecrets.clientId.name: clientId,
            WorkflowSecrets.clientSecret.name: clientSecret,
          }).build(),
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.windows.platform),
          ),
          ...DeployWindowsInstallerBuilder(
            workingDirectory: workingDirectory,
            isDraft: isDraft,
            flightId: flightId,
            tenantId: tenantId,
            clientId: clientId,
            clientSecret: clientSecret,
            sellerId: sellerId,
          ).build(),
        ],
      );
}
