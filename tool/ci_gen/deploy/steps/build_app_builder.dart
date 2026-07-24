import '../../common/api/job_config.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../common/artifacts.dart';
import '../../common/steps/deploy_artifact_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/resolve_artifact_prefix_builder.dart';
import '../../types/step.dart';
import 'flutter_build_builder.dart';
import 'generate_build_number_builder.dart';

base mixin BuildAppConfig
    on
        JobConfig,
        ProjectSetupConfig,
        GenerateBuildNumberConfig,
        FlutterBuildConfig,
        ResolveArtifactPrefixConfig {
  String get artifactDir;

  ArtifactType get artifactType;

  IPlatformMatrixSelector get buildPlatform;

  @override
  bool get withDartTestTools => true;

  @override
  bool get releaseMode => true;
}

class BuildAppBuilder implements StepBuilder {
  static final artifactNameOutput = DeployArtifactBuilder.artifactNameOutput;

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
    ...DeployArtifactBuilder(
      config: config,
      type: config.artifactType,
      platform: config.buildPlatform,
      path: '${config.workingDirectory}/${config.artifactDir}',
    ).build(),
  ];
}
