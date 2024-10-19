import '../../../common/api/job_builder.dart';
import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/environments.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/validate_inputs_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_android_app_builder.dart';

final class DeployAndroidJobBuilder implements JobBuilder {
  final JobIdOutput releaseCreated;
  final Expression enabledPlatforms;
  final Expression workingDirectory;
  final Expression googlePlayTrack;
  final Expression googlePlayReleaseStatus;
  final Expression googlePlayKey;

  const DeployAndroidJobBuilder({
    required this.releaseCreated,
    required this.enabledPlatforms,
    required this.workingDirectory,
    required this.googlePlayTrack,
    required this.googlePlayReleaseStatus,
    required this.googlePlayKey,
  });

  @override
  JobId get id => const JobId('deploy_android');

  @override
  Job build() => Job(
        name: 'Deploy android app to Google Play',
        runsOn: RunsOn.macosLatest.id,
        needs: {releaseCreated.jobId},
        ifExpression:
            releaseCreated.expression.eq(const Expression.literal('true')) &
                EnabledPlatforms.check(
                  enabledPlatforms,
                  Expression.literal(FlutterPlatform.android.platform),
                ),
        environment: Environments.googlePlay,
        steps: [
          ...ValidateInputsBuilder({
            WorkflowSecrets.googlePlayKey.name: googlePlayKey,
          }).build(),
          ...DeployAndroidAppBuilder(
            workingDirectory: workingDirectory,
            googlePlayTrack: googlePlayTrack,
            googlePlayReleaseStatus: googlePlayReleaseStatus,
            googlePlayKey: googlePlayKey,
          ).build(),
        ],
      );
}
