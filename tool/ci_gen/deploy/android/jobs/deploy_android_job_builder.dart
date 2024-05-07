import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/environments.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/deploy_android_app_builder.dart';

final class DeployAndroidJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  final Expression enabledPlatforms;
  final JobIdOutput releaseCreated;
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;
  final Expression workingDirectory;
  final Expression sentryAuthToken;
  final JobIdOutput buildNumber;
  final Expression googlePlayTrack;
  final Expression googlePlayReleaseStatus;
  final Expression googlePlayKey;

  const DeployAndroidJobBuilder({
    required this.enabledPlatforms,
    required this.releaseCreated,
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required this.workingDirectory,
    required this.buildNumber,
    required this.googlePlayTrack,
    required this.googlePlayReleaseStatus,
    required this.sentryAuthToken,
    required this.googlePlayKey,
  });

  @override
  JobId get id => const JobId('deploy_android');

  @override
  Job build() => Job(
        name: 'Deploy android app to Google Play',
        runsOn: RunsOn.macosLatestArm64.id,
        needs: {
          releaseCreated.jobId,
          buildNumber.jobId,
        },
        environment: Environments.googlePlay,
        ifExpression:
            releaseCreated.expression.eq(const Expression.literal('true')) &
                EnabledPlatforms.check(
                  enabledPlatforms,
                  Expression.literal(FlutterPlatform.android.platform),
                ),
        steps: [
          ...buildSetupSdkSteps(),
          ...DeployAndroidAppBuilder(
            workingDirectory: workingDirectory,
            sentryAuthToken: sentryAuthToken,
            buildNumber: buildNumber.expression,
            googlePlayTrack: googlePlayTrack,
            googlePlayReleaseStatus: googlePlayReleaseStatus,
            googlePlayKey: googlePlayKey,
            pubTool: pubTool,
          ).build(),
        ],
      );
}
