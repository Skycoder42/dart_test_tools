import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../common/steps/release_entry_builder.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

final class ReleaseJobConfig extends JobConfig
    with WorkingDirectoryConfig, ReleaseEntryConfig, ReleaseConfig {
  late final releaseRef = inputContext(WorkflowInputs.releaseRef);

  @override
  bool get withToken => true;

  ReleaseJobConfig(super.inputContext, super.secretContext);
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
