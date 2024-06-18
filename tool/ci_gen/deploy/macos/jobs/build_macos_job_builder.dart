import '../../../common/jobs/sdk_job_builder.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/build_macos_dmg_builder.dart';

final class BuildMacosJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  final Expression workingDirectory;
  final Expression removePubspecOverrides;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression dmgConfigPath;
  final Expression dartDefines;

  const BuildMacosJobBuilder({
    required this.flutterSdkChannel,
    required this.workingDirectory,
    required this.removePubspecOverrides,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.dmgConfigPath,
    required this.dartDefines,
  });

  @override
  JobId get id => const JobId('build_macos');

  @override
  Job build() => Job(
        name: 'Build macos dmg image',
        runsOn: RunsOn.macosLatest.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.value(FlutterPlatform.macos.platform),
          ),
          ...BuildMacosDmgBuilder(
            workingDirectory: workingDirectory,
            removePubspecOverrides: removePubspecOverrides,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            buildNumberArgs: buildNumberArgs,
            dmgConfigPath: dmgConfigPath,
            dartDefines: dartDefines,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
