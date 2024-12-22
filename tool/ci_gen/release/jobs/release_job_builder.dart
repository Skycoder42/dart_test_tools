import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/contexts.dart';
import '../../common/steps/release_entry_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

final class ReleaseJobConfig extends JobConfig
    with ReleaseEntryConfig, ReleaseConfig {
  final Expression releaseRef;

  ReleaseJobConfig({
    required this.releaseRef,
    required Expression dartSdkVersion,
    required Expression workingDirectory,
    required Expression tagPrefix,
    required Expression githubToken,
  }) {
    this.dartSdkVersion = dartSdkVersion;
    this.workingDirectory = workingDirectory;
    this.tagPrefix = tagPrefix;
    this.githubToken = githubToken;
    expand();
  }
}

class ReleaseJobBuilder implements JobBuilder {
  final ReleaseJobConfig config;

  ReleaseJobBuilder({
    required this.config,
  });

  @override
  JobId get id => const JobId('release');

  JobIdOutput get updateOutput => id.output('update');

  JobIdOutput get versionOutput => id.output('version');

  @override
  Job build() => Job(
        name: 'Create release if needed',
        runsOn: 'ubuntu-latest',
        ifExpression: Github.ref.eq(config.releaseRef),
        outputs: {
          updateOutput: ReleaseBuilder.versionUpdate,
          versionOutput: ReleaseBuilder.versionOutput,
        },
        steps: [
          ...ReleaseBuilder(config: config).build(),
        ],
      );
}
