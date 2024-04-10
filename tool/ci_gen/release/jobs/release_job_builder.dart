import '../../common/api/job_builder.dart';
import '../../common/contexts.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

class ReleaseJobBuilder implements JobBuilder {
  final Expression releaseRef;
  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression tagPrefix;
  final Expression githubToken;

  ReleaseJobBuilder({
    required this.releaseRef,
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.tagPrefix,
    required this.githubToken,
  });

  @override
  JobId get id => const JobId('release');

  JobIdOutput get updateOutput => id.output('update');

  JobIdOutput get versionOutput => id.output('version');

  @override
  Job build() => Job(
        name: 'Create release if needed',
        runsOn: 'ubuntu-latest',
        ifExpression: Github.ref.eq(releaseRef),
        outputs: {
          updateOutput: ReleaseBuilder.versionUpdate,
          versionOutput: ReleaseBuilder.versionOutput,
        },
        steps: [
          ...ReleaseBuilder(
            dartSdkVersion: dartSdkVersion,
            workingDirectory: workingDirectory,
            tagPrefix: tagPrefix,
            githubToken: githubToken,
          ).build(),
        ],
      );
}
