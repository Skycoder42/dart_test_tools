import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'checkout_builder.dart';
import 'project_prepare_builder.dart';

class ProjectSetupBuilder implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final String pubTool;
  final String runTool;
  final Expression? ifExpression;
  final bool skipYqInstall;

  const ProjectSetupBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.pubTool,
    required this.runTool,
    this.ifExpression,
    this.skipYqInstall = false,
  });

  @override
  Iterable<Step> build() => [
        if (!skipYqInstall) ...[
          Step.run(
            name: 'Install yq (Windows)',
            ifExpression:
                const Expression("runner.os == 'Windows'") & ifExpression,
            run: 'choco install yq',
          ),
          Step.run(
            name: 'Install yq and coreutils (macOS)',
            ifExpression:
                const Expression("runner.os == 'macOS'") & ifExpression,
            run: r'''
brew install yq coreutils
echo "$(brew --prefix)/opt/coreutils/libexec/gnubin" >> $GITHUB_PATH
''',
          ),
        ],
        ...CheckoutBuilder(
          repository: repository,
          ifExpression: ifExpression,
        ).build(),
        ...ProjectPrepareBuilder(
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: ifExpression,
        ).build(),
      ];
}
