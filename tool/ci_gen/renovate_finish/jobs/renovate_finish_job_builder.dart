import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/contexts.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/renovate_finish_builder.dart';

final class RenovateFinishJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with RenovateFinishConfig;

class const RenovateFinishJobBuilder({
  required final RenovateFinishJobConfig config,
}) implements JobBuilder {
  @override
  JobId get id => const JobId('finish');

  @override
  Job build() {
    final pullRequest = Github.event.property('pull_request');
    return Job(
      name: 'Finish Renovate PR',
      // Only Renovate's own PRs: opened with GITHUB_TOKEN from a renovate/
      // branch of this repository.
      ifExpression:
          Github.eventName.eq(const .literal('pull_request')) &
          pullRequest
              .property('user')
              .property('login')
              .eq(const .literal('github-actions[bot]')) &
          Functions.startsWith(Github.headRef, const .literal('renovate/')) &
          pullRequest
              .property('head')
              .property('repo')
              .property('full_name')
              .eq(Github.repository),
      runsOn: RunsOn.ubuntuLatest.id,
      permissions: const {
        'contents': 'write',
        'pull-requests': 'write',
        'actions': 'write',
      },
      steps: [...RenovateFinishBuilder(config: config).build()],
    );
  }
}
