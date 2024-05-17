import '../../../common/jobs/sdk_job_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/build_web_archive_builder.dart';

final class BuildWebJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression baseHref;
  final Expression dartDefines;

  const BuildWebJobBuilder({
    required this.flutterSdkChannel,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.baseHref,
    required this.dartDefines,
  });

  @override
  JobId get id => const JobId('build_web');

  @override
  Job build() => Job(
        name: 'Build web archive',
        runsOn: RunsOn.ubuntuLatest.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.web.platform),
          ),
          ...BuildWebArchiveBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            buildNumberArgs: buildNumberArgs,
            baseHref: baseHref,
            dartDefines: dartDefines,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
