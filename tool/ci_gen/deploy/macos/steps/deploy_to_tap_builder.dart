import '../../../common/actions/install_tools_action_builder.dart';
import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/contexts.dart';
import '../../../common/inputs.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../types/env.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/step.dart';

base mixin DeployToTapConfig
    on JobConfig, SdkJobConfig, WorkingDirectoryConfig {
  late final targetRepo = inputContext(WorkflowInputs.targetRepo);
  late final targetRepoToken = secretContext(WorkflowSecrets.targetRepoToken);
}

class DeployToTapBuilder implements StepBuilder {
  static const generateCaskStepId = StepId('generate-cask');
  static final caskNameOutput = generateCaskStepId.output('caskName');

  final DeployToTapConfig config;
  final Expression releaseVersion;

  const DeployToTapBuilder({
    required this.config,
    required this.releaseVersion,
  });

  @override
  Iterable<Step> build() => [
    InstallToolsActionBuilder.step(withDartTestTools: true),
    ...const CheckoutBuilder(path: 'src').build(),
    ...CheckoutBuilder(
      repository: config.targetRepo,
      path: 'tap',
      token: config.targetRepoToken,
      persistCredentials: const ExpressionOrValue.value(true),
    ).build(),
    Step.run(
      id: generateCaskStepId,
      name: 'Generate cask formula',
      run:
          '${config.pubTool} global run dart_test_tools:generate_cask '
          "--input 'src/${config.workingDirectory}' --output tap",
    ),
    Step.run(
      name: 'Stage cask update',
      run: 'git add Casks/${caskNameOutput.expression}.rb',
      workingDirectory: 'tap',
    ),
    Step.run(
      name: 'Commit tap update',
      run:
          "git -c user.name='github-actions[bot]' "
          // ignore: missing_whitespace_between_adjacent_strings no space required
          '-c user.email='
          "'41898282+github-actions[bot]@users.noreply.github.com' "
          'commit -m '
          "'Updated cask ${caskNameOutput.expression} to v$releaseVersion' "
          '--author '
          "'${Github.actor} <${Github.actor}@users.noreply.github.com>'",
      workingDirectory: 'tap',
    ),
    Step.run(
      name: 'Tap local repository',
      run: 'brew tap ${config.targetRepo} tap',
    ),
    Step.run(
      name: 'Audit generated cask',
      run:
          'brew audit --arch all --strict --git --online --no-signing '
          "--token-conflicts --cask '${config.targetRepo}/${caskNameOutput.expression}'",
      env: Env({
        'HOMEBREW_GITHUB_API_TOKEN': config.targetRepoToken.toString(),
      }),
    ),
    const Step.run(
      name: 'Push tap update to remote',
      run: 'git push origin',
      workingDirectory: 'tap',
    ),
  ];
}
