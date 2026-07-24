import '../../../common/api/job_config.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/environments.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/resolve_artifact_prefix_builder.dart';
import '../../../common/steps/validate_inputs_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_windows_installer_builder.dart';

final class DeployWindowsJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ResolveArtifactPrefixConfig,
        DeployWindowsInstallerConfig,
        FlutterSdkJobConfig {
  DeployWindowsJobConfig(super.inputContext, super.secretContext);
}

final class DeployWindowsJobBuilder
    extends SdkJobBuilder<DeployWindowsJobConfig>
    with FlutterSdkJobBuilderMixin<DeployWindowsJobConfig> {
  const DeployWindowsJobBuilder({required super.config});

  @override
  JobId get id => const JobId('deploy_windows');

  @override
  Job build() => Job(
    name: 'Publish MSIX installer to Microsoft Store',
    runsOn: RunsOn.windowsLatest.id,
    environment: Environments.msstore,
    steps: [
      ...ValidateInputsBuilder({
        WorkflowSecrets.tenantId.name: config.tenantId,
        WorkflowSecrets.sellerId.name: config.sellerId,
        WorkflowSecrets.clientId.name: config.clientId,
        WorkflowSecrets.clientSecret.name: config.clientSecret,
      }).build(),
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(
          FlutterPlatform.windows.platform,
        ),
      ),
      ...DeployWindowsInstallerBuilder(config: config).build(),
    ],
  );
}
