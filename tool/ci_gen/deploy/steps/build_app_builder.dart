import '../../common/api/step_builder.dart';
import '../../common/steps/install_dart_test_tools_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'flutter_build_builder.dart';
import 'generate_build_number_builder.dart';

class BuildAppBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression dartDefines;
  final String pubTool;
  final String runTool;
  final String buildTarget;
  final String? buildArgs;
  final String artifactDir;
  final List<Step> packageSteps;

  const BuildAppBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.dartDefines,
    required this.pubTool,
    required this.runTool,
    required this.buildTarget,
    this.buildArgs,
    required this.artifactDir,
    this.packageSteps = const [],
  });

  @override
  Iterable<Step> build() => [
        ...const InstallDartTestToolsBuilder().build(),
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          releaseMode: true,
          isFlutter: const ExpressionOrValue.value(true),
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        ...GenerateBuildNumberBuilder(
          buildNumberArgs: buildNumberArgs,
          workingDirectory: workingDirectory,
        ).build(),
        ...FlutterBuildBuilder(
          buildNumber: GenerateBuildNumberBuilder.buildNumberOutput.expression,
          workingDirectory: workingDirectory,
          dartDefines: dartDefines,
          buildTarget: buildTarget,
          buildArgs: buildArgs,
        ).build(),
        ...packageSteps,
        Step.uses(
          name: 'Upload app and debug info',
          uses: Tools.actionsUploadArtifact,
          withArgs: {
            'name': 'app-deployment-$buildTarget',
            'path': '$workingDirectory/$artifactDir',
            'retention-days': 1,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
