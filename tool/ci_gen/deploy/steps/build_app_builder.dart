import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../types/step.dart';
import 'flutter_build_builder.dart';
import 'generate_build_number_builder.dart';

base mixin BuildAppConfig
    on
        JobConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig {
  String get artifactDir;

  @override
  bool get withDartTestTools => true;

  @override
  bool get releaseMode => true;

  @override
  late final artifactDependencies = inputContext(
    WorkflowInputs.artifactDependencies,
  );
}

class BuildAppBuilder implements StepBuilder {
  final BuildAppConfig config;
  final List<Step> preBuildSteps;
  final List<String> cleanupPaths;
  final List<Step> packageSteps;

  const BuildAppBuilder({
    required this.config,
    this.preBuildSteps = const [],
    this.cleanupPaths = const [],
    this.packageSteps = const [],
  });

  @override
  Iterable<Step> build() => [
    ...ProjectSetupBuilder(config: config).build(),
    ...GenerateBuildNumberBuilder(config: config).build(),
    ...FlutterBuildBuilder(
      buildNumber: GenerateBuildNumberBuilder.buildNumberOutput.expression,
      config: config,
      preBuildSteps: preBuildSteps,
      cleanupPaths: cleanupPaths,
    ).build(),
    ...packageSteps,
    Step.uses(
      name: 'Upload app and debug info',
      uses: Tools.actionsUploadArtifact,
      withArgs: {
        'name': 'app-deployment-${config.buildTarget}',
        'path': '${config.workingDirectory}/${config.artifactDir}',
        'retention-days': 1,
        'if-no-files-found': 'error',
      },
    ),
  ];
}
