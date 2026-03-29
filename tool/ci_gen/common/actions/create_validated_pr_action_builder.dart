import '../../types/action.dart';
import '../../types/action_runs.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/input.dart';
import '../../types/step.dart';
import '../api/action_builder.dart';
import '../api/workflow_input.dart';
import '../contexts.dart';
import '../tools.dart';

class CreateValidatedPrActionBuilder implements ActionBuilder {
  static const _actionName = 'create-validated-pr';
  static const _displayName = 'Create validated pull request';
  static const _prBranchNameInput = WorkflowInput(
    name: 'prBranchName',
    input: Input.action(
      required: true,
      description: 'The name of the pr branch to be created or updated.',
    ),
  );
  static const _prCommitMessageInput = WorkflowInput(
    name: 'prCommitMessage',
    input: Input.action(
      required: true,
      description: 'The commit message of the pull request.',
    ),
  );
  static const _prTitleInput = WorkflowInput(
    name: 'prTitle',
    input: Input.action(
      required: false,
      description:
          'The title of the pull request. '
          'If unset, the commit message will be used as title.',
    ),
  );
  static const _prBodyInput = WorkflowInput(
    name: 'prBody',
    input: Input.action(
      required: true,
      description:
          'The description body of the pull request or the path to '
          'a markdown file containing it. '
          'You need to set "prBodyIsPath" for the second variant as well.',
    ),
  );
  static const _prBodyIsPathInput = WorkflowInput(
    name: 'prBodyIsPath',
    input: Input.action(
      required: false,
      defaultValue: 'false',
      description:
          'Whether the "prBody" is simple text (false) '
          'or the path to a markdown file (true).',
    ),
  );
  static const _validationWorkflowInput = WorkflowInput(
    name: 'validationWorkflow',
    input: Input.action(
      required: true,
      description:
          'The name or id of the workflow that must be run and succeed '
          'for the pull request to be able to merge.',
    ),
  );
  static const _validationTimeoutInput = WorkflowInput(
    name: 'validationTimeout',
    input: Input.action(
      required: false,
      defaultValue: '3600',
      description:
          'The timeout (in seconds) to wait for the validation to complete.',
    ),
  );

  static const createPrStepId = StepId('create-pull-request');
  static final pullRequestNumber = createPrStepId.output('pull-request-number');
  static final pullRequestBranch = createPrStepId.output('pull-request-branch');

  const CreateValidatedPrActionBuilder();

  static Step step({
    StepId? id,
    String? name,
    Expression? ifExpression,
    bool? continueOnError,
    required ExpressionOrValue prBranchName,
    required ExpressionOrValue prCommitMessage,
    ExpressionOrValue? prTitle,
    required ExpressionOrValue prBody,
    bool? prBodyIsPath,
    required ExpressionOrValue validationWorkflow,
    int? validationTimeout,
  }) => Step.uses(
    id: id,
    name: name ?? _displayName,
    ifExpression: ifExpression,
    uses: 'Skycoder42/dart_test_tools/.github/actions/$_actionName@main',
    continueOnError: continueOnError,
    withArgs: {
      _prBranchNameInput.name: prBranchName.toString(),
      _prCommitMessageInput.name: prCommitMessage.toString(),
      if (prTitle != null) _prTitleInput.name: prTitle.toString(),
      _prBodyInput.name: prBody.toString(),
      if (prBodyIsPath != null)
        _prBodyIsPathInput.name: prBodyIsPath.toString(),
      _validationWorkflowInput.name: validationWorkflow.toString(),
      if (validationTimeout != null)
        _validationTimeoutInput.name: validationTimeout.toString(),
    },
  );

  @override
  String get name => _actionName;

  @override
  Action build() {
    final inputContext = WorkflowInputContext();
    final prBranchName = inputContext(_prBranchNameInput);
    final prCommitMessage = inputContext(_prCommitMessageInput);
    final prTitle = inputContext(_prTitleInput);
    final prBody = inputContext(_prBodyInput);
    final prBodyIsPath = inputContext(_prBodyIsPathInput);
    final validationWorkflow = inputContext(_validationWorkflowInput);
    final validationTimeout = inputContext(_validationTimeoutInput);

    return Action(
      name: _displayName,
      description: 'Creates a PR against the current branch and validates it.',
      inputs: inputContext.createInputs(),
      runs: ActionsRuns.composite([
        Step.uses(
          id: createPrStepId,
          name: 'Create pull request',
          uses: Tools.peterEvansCreatePullRequest,
          withArgs: {
            'branch': prBranchName.toString(),
            'delete-branch': true,
            'commit-message': prCommitMessage.toString(),
            'title': Functions.case$([
              (prTitle.ne(.empty), .expression(prTitle)),
            ], .expression(prCommitMessage)).toString(),
            'body': Functions.case$([
              (
                prBodyIsPath.eq(const Expression.literal('false')),
                ExpressionOrValue.expression(prBody),
              ),
            ]).toString(),
            'body-path': Functions.case$([
              (
                prBodyIsPath.eq(const Expression.literal('true')),
                ExpressionOrValue.expression(prBody),
              ),
            ]).toString(),
            'assignees': Github.repositoryOwner.toString(),
          },
        ),
        Step.uses(
          name: 'Manually validate pull request',
          uses: Tools.bencUkWorkflowDispatch,
          withArgs: {
            'workflow': validationWorkflow.toString(),
            'ref': 'refs/heads/${pullRequestBranch.expression}',
            'wait-for-completion': true,
            'sync-status': true,
            'wait-timeout-seconds': validationTimeout.toString(),
          },
        ),
        Step.uses(
          name: 'Mention assignees',
          uses: Tools.thollanderActionsCommentPullRequest,
          ifExpression: Functions.success,
          withArgs: {
            'pr-number': pullRequestNumber.expression.toString(),
            'message':
                'Your review has been requested @${Github.repositoryOwner}',
          },
        ),
        Step.uses(
          name: 'Mention assignees',
          uses: Tools.thollanderActionsCommentPullRequest,
          ifExpression:
              Functions.failure &
              pullRequestNumber.expression.ne(Expression.empty),
          withArgs: {
            'pr-number': pullRequestNumber.expression.toString(),
            'message':
                'Automatic validation of pull request failed! '
                '@${Github.repositoryOwner} please validate it manually.',
          },
        ),
      ]),
    );
  }
}
