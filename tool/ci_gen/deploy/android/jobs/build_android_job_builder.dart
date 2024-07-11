import '../../../common/jobs/sdk_job_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/build_android_app_builder.dart';

final class BuildAndroidJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;
  final Expression workingDirectory;
  final Expression removePubspecOverrides;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression primaryLocale;
  final Expression dartDefines;
  final Expression keystore;
  final Expression keystorePassword;

  const BuildAndroidJobBuilder({
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required this.workingDirectory,
    required this.removePubspecOverrides,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.primaryLocale,
    required this.dartDefines,
    required this.keystore,
    required this.keystorePassword,
  });

  @override
  JobId get id => const JobId('build_android');

  @override
  Job build() => Job(
        name: 'Build android app bundle',
        runsOn: RunsOn.ubuntuLatest.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.android.platform),
          ),
          ...BuildAndroidAppBuilder(
            workingDirectory: workingDirectory,
            removePubspecOverrides: removePubspecOverrides,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            buildNumberArgs: buildNumberArgs,
            primaryLocale: primaryLocale,
            dartDefines: dartDefines,
            keystore: keystore,
            keystorePassword: keystorePassword,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
