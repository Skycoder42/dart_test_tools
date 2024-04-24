import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/steps/install_dart_test_tools_builder.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/step.dart';

class DeployToTapBuilder implements StepBuilder {
  static const generateCaskStepId = StepId('generate-cask');
  static final caskNameOutput = generateCaskStepId.output('caskName');

  final Expression targetRepo;
  final Expression workingDirectory;
  final Expression releaseVersion;
  final Expression targetRepoToken;
  final String pubTool;

  const DeployToTapBuilder({
    required this.targetRepo,
    required this.workingDirectory,
    required this.releaseVersion,
    required this.targetRepoToken,
    required this.pubTool,
  });

  @override
  Iterable<Step> build() => [
        ...const InstallDartTestToolsBuilder().build(),
        ...const CheckoutBuilder(
          path: 'src',
        ).build(),
        ...CheckoutBuilder(
          repository: targetRepo,
          path: 'tap',
          token: targetRepoToken,
          persistCredentials: const ExpressionOrValue.value(true),
        ).build(),
        Step.run(
          id: generateCaskStepId,
          name: 'Generate cask formula',
          run: '$pubTool global run dart_test_tools:generate_cask '
              "--input 'src/$workingDirectory' --output tap",
        ),
        Step.run(
          name: 'Stage cask update',
          run: 'git add Casks/${caskNameOutput.expression}.rb',
          workingDirectory: 'tap',
        ),
        Step.run(
          name: 'Commit tap update',
          run: "git -c user.name='github-actions[bot]' "
              // ignore: missing_whitespace_between_adjacent_strings
              '-c user.email='
              "'41898282+github-actions[bot]@users.noreply.github.com' "
              "commit -m 'Updated cask to v$releaseVersion' "
              '--author '
              "'${Github.actor} <${Github.actor}@users.noreply.github.com>'",
          workingDirectory: 'tap',
        ),
        Step.run(
          name: 'Tap local repository',
          run: 'brew tap $targetRepo tap',
        ),
        Step.run(
          name: 'Audit generated cask',
          run: 'brew audit --arch all --strict --git --online --no-signing '
              "--token-conflicts --cask '$targetRepo/${caskNameOutput.expression}'",
        ),
        const Step.run(
          name: 'Push tap update to remite',
          run: 'git push origin',
          workingDirectory: 'tap',
        ),
      ];
}
