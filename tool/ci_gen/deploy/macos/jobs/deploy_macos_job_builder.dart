import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/environments.dart';
import '../../../common/inputs.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/secrets.dart';
import '../../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../../steps/validate_inputs_builder.dart';
import '../steps/deploy_to_tap_builder.dart';

final class DeployMacosJobBuilder extends SdkJobBuilder
    with DartSdkJobBuilderMixin {
  final JobIdOutput releaseCreated;
  final JobIdOutput releaseVersion;
  final Expression enabledPlatforms;
  @override
  final Expression dartSdkVersion;
  final Expression targetRepo;
  final Expression workingDirectory;
  final Expression targetRepoToken;

  const DeployMacosJobBuilder({
    required this.releaseCreated,
    required this.releaseVersion,
    required this.enabledPlatforms,
    required this.dartSdkVersion,
    required this.targetRepo,
    required this.workingDirectory,
    required this.targetRepoToken,
  });

  @override
  JobId get id => const JobId('deploy_macos');

  @override
  Job build() => Job(
        name: 'Deploy DMG image to homebrew tap',
        needs: {releaseCreated.jobId, releaseVersion.jobId},
        runsOn: RunsOn.macosLatestArm64.id,
        ifExpression:
            releaseCreated.expression.eq(const Expression.literal('true')) &
                EnabledPlatforms.check(
                  enabledPlatforms,
                  Expression.literal(FlutterPlatform.macos.platform),
                ),
        environment: Environments.homebrew,
        steps: [
          ...ValidateInputsBuilder({
            WorkflowInputs.targetRepo.name: targetRepo,
            WorkflowSecrets.targetRepoToken.name: targetRepoToken,
          }).build(),
          ...buildSetupSdkSteps(),
          ...DeployToTapBuilder(
            targetRepo: targetRepo,
            workingDirectory: workingDirectory,
            releaseVersion: releaseVersion.expression,
            targetRepoToken: targetRepoToken,
            pubTool: pubTool,
          ).build(),
        ],
      );
}
