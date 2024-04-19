import '../../../common/jobs/sdk_job_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/build_windows_installer_builder.dart';

final class BuildWindowsJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression dartDefines;

  const BuildWindowsJobBuilder({
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.dartDefines,
  });

  @override
  JobId get id => const JobId('build_windows');

  @override
  Job build() => Job(
        name: 'Build windows msix installer',
        runsOn: RunsOn.windowsLatest.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.windows.platform),
          ),
          ...BuildWindowsInstallerBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            buildNumberArgs: buildNumberArgs,
            dartDefines: dartDefines,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
