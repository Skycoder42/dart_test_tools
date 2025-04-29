import '../../../common/api/job_config.dart';
import '../../../common/api/matrix_job_builder_mixin.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/inputs.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/steps/install_dart_test_tools_builder.dart';
import '../../../common/steps/update_overrides_builder.dart';
import '../../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../../types/container.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../../steps/generate_build_number_builder.dart';
import '../steps/build_flatpak_bundle_builder.dart';
import '../steps/with_gpg_key.dart';

final class BuildLinuxJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        UpdateOverridesConfig,
        GenerateBuildNumberConfig,
        WithGpgKeyConfig,
        BuildFlatpakBundleConfig,
        DartSdkJobConfig {
  late final flatpakPlatformImage = inputContext(
    WorkflowInputs.flatpakPlatformImage,
  );

  @override
  late final removePubspecOverrides = ExpressionOrValue.expression(
    inputContext(WorkflowInputs.removePubspecOverrides),
  );

  @override
  late final localResolution = ExpressionOrValue.expression(
    inputContext(WorkflowInputs.localResolution),
  );

  @override
  late final artifactDependencies = inputContext(
    WorkflowInputs.artifactDependencies,
  );

  BuildLinuxJobConfig(super.inputContext, super.secretContext);
}

final class FlatpakMatrix extends Matrix<FlatpakArchMatrixSelector> {
  const FlatpakMatrix() : super(FlatpakArchMatrixSelector.values);

  ArchMatrixProperty get arch => const ArchMatrixProperty();

  QEmuArchProperty get qemuArch => const QEmuArchProperty();

  @override
  IMatrixProperty<FlatpakArchMatrixSelector> get selectorProperty => arch;

  @override
  List<IMatrixProperty<FlatpakArchMatrixSelector>> get includeProperties => [
    arch,
    qemuArch,
  ];
}

final class BuildLinuxJobBuilder extends SdkJobBuilder<BuildLinuxJobConfig>
    with
        DartSdkJobBuilderMixin<BuildLinuxJobConfig>,
        MatrixJobBuilderMixin<FlatpakMatrix, FlatpakArchMatrixSelector> {
  BuildLinuxJobBuilder({required super.config})
    : matrix = const FlatpakMatrix();

  @override
  JobId get id => const JobId('build_linux');

  @override
  final FlatpakMatrix matrix;

  @override
  Expression get matrixRunsOn => Expression.fake(RunsOn.ubuntuLatest.id);

  @override
  Job buildGeneric(String runsOn) => Job(
    name: 'Build linux flatpak bundle',
    runsOn: runsOn,
    container: Container(
      image: config.flatpakPlatformImage.toString(),
      options: '--privileged',
    ),
    steps: [
      ...buildSetupSdkSteps(),
      ...const InstallDartTestToolsBuilder().build(),
      ...BuildFlatpakBundleBuilder(
        config: config,
        arch: matrix.arch,
        qemuArch: matrix.qemuArch,
      ).build(),
    ],
  );
}
