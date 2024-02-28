import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class BuildAndroidAppBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final String pubTool;
  final String runTool;

  const BuildAndroidAppBuilder({
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          releaseMode: true,
          pubTool: pubTool,
          runTool: runTool,
          skipYqInstall: true,
        ).build(),
      ];
}
