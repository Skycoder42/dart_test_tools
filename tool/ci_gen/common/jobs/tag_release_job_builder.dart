import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../contexts.dart';
import '../steps/tag_release_builder.dart';

class TagReleaseJobBuilder implements JobBuilder {
  final Set<JobId>? compileJobIds;
  final Expression releaseRef;
  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression tagPrefix;
  final Expression persistCredentials;
  final String? binaryArtifactsPattern;

  const TagReleaseJobBuilder({
    this.compileJobIds,
    required this.releaseRef,
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.tagPrefix,
    required this.persistCredentials,
    this.binaryArtifactsPattern,
  });

  @override
  JobId get id => const JobId('release');

  JobIdOutput get updateOutput => id.output('update');

  JobIdOutput get versionOutput => id.output('version');

  @override
  Job build() => Job(
        name: 'Create release if needed',
        needs: compileJobIds,
        ifExpression: Github.ref.eq(releaseRef),
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
            binaryArtifactsPattern: binaryArtifactsPattern,
          ).build(),
        ],
      );
}
