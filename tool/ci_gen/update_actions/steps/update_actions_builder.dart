import '../../common/actions/create_validated_pr_action_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin UpdateActionsConfig
    on JobConfig, SdkJobConfig, ProjectPrepareConfig {
  late final validationWorkflow = inputContext(
    WorkflowInputs.validationWorkflow,
  );
}

class UpdateActionsBuilder implements StepBuilder {
  static const _detectChangesId = StepId('detect_changes');
  static final _hasChangesOutput = _detectChangesId.output('has_changes');

  final UpdateActionsConfig config;

  const UpdateActionsBuilder({required this.config});

  @override
  Iterable<Step> build() sync* {
    yield* const CheckoutBuilder(
      fetchDepth: 0,
      persistCredentials: .value(true),
    ).build();
    yield* ProjectPrepareBuilder(config: config).build();
    yield Step.run(
      name: 'Update action version pins',
      run: '${config.runTool} tool/ci_update_actions.dart',
    );
    yield Step.run(
      name: 'Regenerate CI workflows',
      run: '${config.runTool} tool/ci_gen.dart',
    );
    yield Step.run(
      id: _detectChangesId,
      name: 'Detect changes',
      run:
          'git diff --quiet'
          ' && ${_hasChangesOutput.bashSetter('false')}'
          ' || ${_hasChangesOutput.bashSetter('true')}',
    );
    yield CreateValidatedPrActionBuilder.step(
      prBranchName: const .value('update-actions'),
      prCommitMessage: const .value('Update GitHub Action versions'),
      prBody: const .value(
        'Automated update of GitHub Action version pins'
        ' and regenerated CI YAML.',
      ),
      validationWorkflow: .expression(config.validationWorkflow),
      ifExpression: _hasChangesOutput.expression.eq(const .literal('true')),
    );
  }
}
