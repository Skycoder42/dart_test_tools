import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../api/job_config.dart';
import '../api/working_directory_config.dart';
import '../contexts.dart';
import '../inputs.dart';
import '../steps/release_entry_builder.dart';
import '../steps/resolve_artifact_prefix_builder.dart';
import '../steps/tag_release_builder.dart';

final class TagReleaseJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with
        WorkingDirectoryConfig,
        ResolveArtifactPrefixConfig,
        ReleaseEntryConfig,
        TagReleaseConfig {
  late final releaseRef = inputContext(WorkflowInputs.releaseRef);
}

class const TagReleaseJobBuilder({
  final Set<JobId>? compileJobIds,
  required final TagReleaseJobConfig config,
  final bool failOnUnmatchedFiles = true,
}) implements JobBuilder {
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
    steps: [
      ...TagReleaseBuilder(
        config: config,
        failOnUnmatchedFiles: failOnUnmatchedFiles,
      ).build(),
    ],
  );
}
