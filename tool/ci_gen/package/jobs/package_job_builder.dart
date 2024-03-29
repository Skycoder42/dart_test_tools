import '../../common/jobs/sdk_job_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/package_builder.dart';

final class PackageJobBuilder extends SdkJobBuilder
    with DartSdkJobBuilderMixin {
  @override
  JobId get id => const JobId('package');

  @override
  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;

  PackageJobBuilder({
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
  });

  @override
  Job build() => Job(
        name: 'Create dart package artifact',
        runsOn: 'ubuntu-latest',
        steps: [
          ...buildSetupSdkSteps(),
          ...PackageBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
