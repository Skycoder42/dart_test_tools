import '../../../common/api/step_builder.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

class BuildWindowsInstallerBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression removePubspecOverrides;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression dartDefines;
  final String pubTool;
  final String runTool;

  const BuildWindowsInstallerBuilder({
    required this.workingDirectory,
    required this.removePubspecOverrides,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.dartDefines,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...BuildAppBuilder(
          workingDirectory: workingDirectory,
          removePubspecOverrides:
              ExpressionOrValue.expression(removePubspecOverrides),
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          buildNumberArgs: buildNumberArgs,
          dartDefines: dartDefines,
          pubTool: pubTool,
          runTool: runTool,
          buildTarget: 'windows',
          artifactDir: 'build/windows/msix',
          packageSteps: [
            Step.run(
              name: 'Create msix package',
              run: 'dart run msix:create --release --store '
                  '--build-windows false '
                  r'--output-path build\windows\msix',
              workingDirectory: workingDirectory.toString(),
            ),
          ],
        ).build(),
      ];
}
