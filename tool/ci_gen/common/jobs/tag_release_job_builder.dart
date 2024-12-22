import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../api/job_config.dart';
import '../contexts.dart';
import '../steps/release_entry_builder.dart';
import '../steps/tag_release_builder.dart';

final class TagReleaseJobConfig extends JobConfig
    with ReleaseEntryConfig, TagReleaseConfig {
  final Expression releaseRef;

  TagReleaseJobConfig({
    required this.releaseRef,
    required Expression dartSdkVersion,
    required Expression workingDirectory,
    required Expression tagPrefix,
    required Expression persistCredentials,
    String? binaryArtifactsPattern,
  }) {
    this.dartSdkVersion = dartSdkVersion;
    this.workingDirectory = workingDirectory;
    this.tagPrefix = tagPrefix;
    this.persistCredentials = persistCredentials;
    this.binaryArtifactsPattern = binaryArtifactsPattern;
    expand();
  }
}

class TagReleaseJobBuilder implements JobBuilder {
  final Set<JobId>? compileJobIds;
  final TagReleaseJobConfig config;

  const TagReleaseJobBuilder({
    this.compileJobIds,
    required this.config,
  });

  @override
  JobId get id => const JobId('release');

  JobIdOutput get updateOutput => id.output('update');

  JobIdOutput get versionOutput => id.output('version');

  @override
  Job build() => Job(
        name: 'Create release if needed',
        needs: compileJobIds,
        ifExpression: Github.ref.eq(config.releaseRef),
        permissions: const {
          'contents': 'write',
        },
        outputs: {
          updateOutput: TagReleaseBuilder.updateOutput,
          versionOutput: TagReleaseBuilder.versionOutput,
        },
        runsOn: 'ubuntu-latest',
        steps: [
          ...TagReleaseBuilder(config: config).build(),
        ],
      );
}
