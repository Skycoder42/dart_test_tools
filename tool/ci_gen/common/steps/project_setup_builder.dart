import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../contexts.dart';
import 'checkout_builder.dart';
import 'project_prepare_builder.dart';

class ProjectSetupBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression? artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression? removePubspecOverrides;
  final bool releaseMode;
  final String pubTool;
  final String runTool;
  final bool skipYqInstall;

  const ProjectSetupBuilder({
    required this.workingDirectory,
    this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    this.removePubspecOverrides,
    this.releaseMode = false,
    required this.pubTool,
    required this.runTool,
    this.skipYqInstall = false,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install scoop',
          ifExpression: Runner.os.eq(const Expression.literal('Windows')),
          shell: 'pwsh',
          run: r'''
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
Join-Path (Resolve-Path ~).Path "scoop\shims" >> $Env:GITHUB_PATH
''',
        ),
        if (!skipYqInstall) ...[
          Step.run(
            name: 'Install yq (Windows)',
            ifExpression: Runner.os.eq(const Expression.literal('Windows')),
            run: 'scoop install yq',
          ),
          Step.run(
            name: 'Install yq and coreutils (macOS)',
            ifExpression: Runner.os.eq(const Expression.literal('macOS')),
            run: r'''
brew install yq coreutils
echo "$(brew --prefix)/opt/coreutils/libexec/gnubin" >> $GITHUB_PATH
''',
          ),
        ],
        ...CheckoutBuilder(
          artifactDependencies: artifactDependencies,
        ).build(),
        ...ProjectPrepareBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          removePubspecOverrides: removePubspecOverrides,
          releaseMode: releaseMode,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
      ];
}
