import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

class ReleaseJobBuilder implements JobBuilder {
  static const jobId = JobId('release');
  static final updateOutput = jobId.output('update');
  static final versionOutput = jobId.output('version');

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
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Create release if needed',
        runsOn: 'ubuntu-latest',
        ifExpression: const Expression('github.ref').eq(releaseRef),
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
