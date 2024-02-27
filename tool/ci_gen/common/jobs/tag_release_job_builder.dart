import '../api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/tag_release_builder.dart';

class TagReleaseJobBuilder implements JobBuilder {
  static const jobId = JobId('release');
  static final updateOutput = jobId.output('update');
  static final versionOutput = jobId.output('version');

  final JobId compileJobId;
  final Expression releaseRef;
  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression tagPrefix;
  final Expression persistCredentials;

  const TagReleaseJobBuilder({
    required this.compileJobId,
    required this.releaseRef,
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.tagPrefix,
    required this.persistCredentials,
  });

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Create release if needed',
        needs: {compileJobId},
        ifExpression: const Expression('github.ref').eq(releaseRef),
        permissions: const {
          'contents': 'write',
        },
        outputs: {
          updateOutput: TagReleaseBuilder.updateOutput,
          versionOutput: TagReleaseBuilder.versionOutput,
        },
        runsOn: 'ubuntu-latest',
        steps: [
          ...TagReleaseBuilder(
            dartSdkVersion: dartSdkVersion,
            workingDirectory: workingDirectory,
            tagPrefix: tagPrefix,
            persistCredentials: persistCredentials,
            binaryArtifactsPattern: 'binaries-*',
          ).build(),
        ],
      );
}
