import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../api/job_config.dart';
import '../api/working_directory_config.dart';
import '../contexts.dart';
import '../inputs.dart';
import '../steps/release_entry_builder.dart';
import '../steps/tag_release_builder.dart';

final class TagReleaseJobConfig extends JobConfig
    with WorkingDirectoryConfig, ReleaseEntryConfig, TagReleaseConfig {
  late final releaseRef = inputContext(WorkflowInputs.releaseRef);

  @override
  final String? binaryArtifactsPattern;

  TagReleaseJobConfig(
    super.inputContext,
    super.secretContext, {
    required this.binaryArtifactsPattern,
  });
}

class TagReleaseJobBuilder implements JobBuilder {
  final Set<JobId>? compileJobIds;
  final TagReleaseJobConfig config;

  const TagReleaseJobBuilder({this.compileJobIds, required this.config});

  @override
  JobId get id => const JobId('release');

  JobIdOutput get updateOutput => id.output('update');

  JobIdOutput get versionOutput => id.output('version');

  @override
  Job build() => Job(
    name: 'Create release if needed',
    needs: compileJobIds,
    ifExpression: Github.ref.eq(config.releaseRef),
    permissions: const {'contents': 'write'},
    outputs: {
      updateOutput: TagReleaseBuilder.updateOutput,
      versionOutput: TagReleaseBuilder.versionOutput,
    },
    runsOn: 'ubuntu-latest',
    steps: [...TagReleaseBuilder(config: config).build()],
  );
}
