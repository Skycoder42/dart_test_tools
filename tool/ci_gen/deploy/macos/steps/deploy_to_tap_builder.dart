import '../../../common/api/step_builder.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/steps/install_dart_test_tools_builder.dart';
import '../../../common/tools.dart';
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
          name: 'Tap local repository',
          run: 'brew tap $targetRepo tap',
        ),
        Step.run(
          name: 'Audit generated cask',
          run: 'brew audit --arch all --strict --git --online --no-signing '
              "--token-conflicts --cask '$targetRepo/${caskNameOutput.expression}'",
        ),
        Step.uses(
          name: 'Commit repository updates',
          uses: Tools.stefanzweifelGitAutoCommitAction,
          withArgs: {
            'commit_message': 'Updated cask to v$releaseVersion',
            'repository': 'tap',
          },
        ),
      ];
}
