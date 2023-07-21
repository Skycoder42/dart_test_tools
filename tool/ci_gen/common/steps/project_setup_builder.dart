import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'checkout_builder.dart';
import 'project_prepare_builder.dart';

class ProjectSetupBuilder implements StepBuilder {
  static const platformCheckStepId = StepId('platform-check');
  static const shouldRunOutput =
      StepIdOutput(platformCheckStepId, 'should-run');

  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final bool releaseMode;
  final String pubTool;
  final String runTool;
  final bool skipYqInstall;
  final Expression? withPlatform;

  const ProjectSetupBuilder({
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
    this.releaseMode = false,
    required this.pubTool,
    required this.runTool,
    this.skipYqInstall = false,
    this.withPlatform,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install scoop',
          ifExpression: const Expression("runner.os == 'Windows'"),
          shell: 'pwsh',
          run: r'iex "& {$(irm get.scoop.sh)} -RunAsAdmin"',
        ),
        if (!skipYqInstall) ...[
          Step.run(
            name: 'Install yq (Windows)',
            ifExpression: const Expression("runner.os == 'Windows'"),
            run: 'scoop install yq',
          ),
          Step.run(
            name: 'Install yq and coreutils (macOS)',
            ifExpression: const Expression("runner.os == 'macOS'"),
            run: r'''
brew install yq coreutils
echo "$(brew --prefix)/opt/coreutils/libexec/gnubin" >> $GITHUB_PATH
''',
          ),
        ],
        ...CheckoutBuilder().build(),
        if (withPlatform != null)
          Step.run(
            id: platformCheckStepId,
            name: 'Check if platform $withPlatform is supported',
            run: '''
set -eo pipefail
isPlatformAllowed=\$(yq 'has("platforms") | not or .platforms | has("$withPlatform")' pubspec.yaml)
echo "Platform enabled: \$isPlatformAllowed"
${shouldRunOutput.bashSetter('\$isPlatformAllowed')}
''',
            workingDirectory: workingDirectory.toString(),
            shell: 'bash',
          ),
        ...ProjectPrepareBuilder(
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          releaseMode: releaseMode,
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: withPlatform != null
              ? shouldRunOutput.expression.eq(Expression.literal("true"))
              : null,
        ).build(),
      ];
}
