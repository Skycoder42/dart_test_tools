import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../types/env.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin RenovateFinishConfig on JobConfig {
  late final succeeded = inputContext(WorkflowInputs.succeeded);
  late final mergeMethod = inputContext(WorkflowInputs.mergeMethod);
  late final dispatchWorkflow = inputContext(WorkflowInputs.dispatchWorkflow);
}

class const RenovateFinishBuilder({required final RenovateFinishConfig config})
    implements StepBuilder {
  static const _mergeStepId = StepId('merge');

  static const _pullRequest = Expression('github.event.pull_request');
  static final _mergeOutcome = Expression('steps.$_mergeStepId.outcome');

  // All values reach the scripts via env, never interpolated into them.
  static final _ghEnv = {
    'GH_TOKEN': Github.token.toString(),
    'PR': _pullRequest.property('number').toString(),
  };

  @override
  Iterable<Step> build() sync* {
    final mergeFailed = _mergeOutcome.eq(const .literal('failure'));

    // Pinning the head SHA merges only the commit whose CI run was approved.
    // If Renovate pushed in between, GitHub refuses the merge.
    yield Step.run(
      id: _mergeStepId,
      name: 'Merge pull request',
      ifExpression: config.succeeded,
      env: Env({
        ..._ghEnv,
        'HEAD_SHA': _pullRequest.property('head').property('sha').toString(),
        'MERGE_METHOD': config.mergeMethod.toString(),
      }),
      run:
          r'gh pr merge "$PR" --repo "$GITHUB_REPOSITORY" --"$MERGE_METHOD" '
          r'--delete-branch --match-head-commit "$HEAD_SHA"',
    );

    // A merge done with GITHUB_TOKEN triggers no push workflow, but
    // workflow_dispatch is allowed - this starts the release chain.
    yield Step.run(
      name: 'Dispatch workflow on the default branch',
      ifExpression:
          config.succeeded & _mergeOutcome.eq(const .literal('success')),
      env: Env({
        'GH_TOKEN': Github.token.toString(),
        'WORKFLOW': config.dispatchWorkflow.toString(),
        // inside a reusable workflow, this is the ref of the caller
        'WORKFLOW_REF': Github.workflowRef.toString(),
        'DEFAULT_BRANCH': Github.event
            .property('repository')
            .property('default_branch')
            .toString(),
      }),
      run: r'''
set -euo pipefail
workflow="$WORKFLOW"
if [ -z "$workflow" ]; then
  # owner/repo/.github/workflows/<file>@<ref> -> <file>
  workflow="${WORKFLOW_REF%@*}"
  workflow="${workflow##*/}"
fi
gh workflow run "$workflow" --repo "$GITHUB_REPOSITORY" --ref "$DEFAULT_BRANCH"
''',
    );

    yield Step.run(
      name: 'Notify reviewer',
      ifExpression:
          Functions.always & (config.succeeded.not | mergeFailed).parenthesized,
      env: Env({
        ..._ghEnv,
        'SUCCEEDED': config.succeeded.toString(),
        'REVIEWER': Github.repositoryOwner.toString(),
      }),
      run: r'''
set -euo pipefail
if [ "$SUCCEEDED" = true ]; then
  what="The automatic merge failed"
else
  what="CI failed"
fi
gh pr comment "$PR" --repo "$GITHUB_REPOSITORY" \
  --body "@$REVIEWER $what: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
''',
    );
  }
}
