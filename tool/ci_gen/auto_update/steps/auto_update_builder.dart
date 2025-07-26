import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/secrets.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/install_dart_test_tools_builder.dart';
import '../../common/steps/install_tools_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin AutoUpdateConfig
    on JobConfig, SdkJobConfig, InstallToolsConfig, WorkingDirectoryConfig {
  late final githubToken = secretContext(WorkflowSecrets.githubToken);
}

class AutoUpdateBuilder implements StepBuilder {
  static const createPrStepId = StepId('create-pull-request');
  static final pullRequestNumber = createPrStepId.output('pull-request-number');

  final AutoUpdateConfig config;

  const AutoUpdateBuilder({required this.config});

  @override
  Iterable<Step> build() sync* {
    yield* _setup();
    yield* _updateDependencies();
    yield* _createPr();
  }

  Iterable<Step> _setup() sync* {
    yield* InstallToolsBuilder(config: config).build();
    yield* const InstallDartTestToolsBuilder().build();
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
    yield Step.run(
      name: 'Update dependencies',
      run:
          '${config.pubTool} global run dart_test_tools:auto_update '
          '--mode update '
          "--target '${config.workingDirectory}' "
          '--bump-version '
          "--report '${Runner.temp}/update_log.md'",
    );
  }

  Iterable<Step> _createPr() sync* {
    yield Step.uses(
      id: createPrStepId,
      name: 'Create pull request',
      uses: Tools.peterEvansCreatePullRequest,
      withArgs: {
        'branch': 'automatic-dependency-updates',
        'delete-branch': true,
        'commit-message': 'Automatic dependency updates',
        'title': 'Automatic dependency updates',
        'body-path': '${Runner.temp}/update_log.md',
        'assignees': Github.repositoryOwner.toString(),
        'token': config.githubToken.toString(),
      },
    );
    yield Step.uses(
      name: 'Mention assignees',
      uses: Tools.thollanderActionsCommentPullRequest,
      withArgs: {
        'pr-number': pullRequestNumber.expression.toString(),
        'message': 'Your review has been requested @${Github.repositoryOwner}',
      },
    );
  }
}
