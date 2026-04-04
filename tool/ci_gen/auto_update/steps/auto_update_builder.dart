import '../../common/actions/create_validated_pr_action_builder.dart';
import '../../common/actions/install_tools_action_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin AutoUpdateConfig on JobConfig, SdkJobConfig, WorkingDirectoryConfig {
  late final flutterCompat = inputContext(WorkflowInputs.flutterCompat);
  late final validationWorkflow = inputContext(
    WorkflowInputs.validationWorkflow,
  );
}

class AutoUpdateBuilder implements StepBuilder {
  static const createPrStepId = StepId('create-pull-request');
  static final pullRequestNumber = createPrStepId.output('pull-request-number');
  static final pullRequestBranch = createPrStepId.output('pull-request-branch');

  final AutoUpdateConfig config;

  const AutoUpdateBuilder({required this.config});

  @override
  Iterable<Step> build() sync* {
    yield* _setup();
    yield* _updateDependencies();
    yield* _createPr();
  }

  Iterable<Step> _setup() sync* {
    yield InstallToolsActionBuilder.step(withDartTestTools: true);
    yield* const CheckoutBuilder(
      fetchDepth: 0,
      persistCredentials: ExpressionOrValue.value(true),
    ).build();
    yield Step.run(
      name: 'Restore dart packages',
      run: '${config.pubTool} get',
      workingDirectory: config.workingDirectory.toString(),
    );
  }

  Iterable<Step> _updateDependencies() sync* {
    final flutterCompatOption =
        config.flutterCompat & const Expression.literal('--flutter-compat') |
        const Expression.literal('--no-flutter-compat');
    yield Step.run(
      name: 'Update dependencies',
      run:
          'auto-update '
          '--mode update '
          "--target '${config.workingDirectory}' "
          '$flutterCompatOption '
          '--bump-version '
          "--report '${Runner.temp}/update_log.md'",
    );
  }

  Iterable<Step> _createPr() sync* {
    yield CreateValidatedPrActionBuilder.step(
      prBranchName: const .value('automatic-dependency-updates'),
      prCommitMessage: const .value('Automatic dependency updates'),
      prBodyIsPath: true,
      prBody: .value('${Runner.temp}/update_log.md'),
      validationWorkflow: .expression(config.validationWorkflow),
    );
  }
}
