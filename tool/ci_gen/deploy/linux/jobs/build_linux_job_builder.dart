import '../../../common/api/matrix_job_builder_mixin.dart';
import '../../../common/environments.dart';
import '../../../common/jobs/sdk_job_builder.dart';
import '../../../common/steps/install_dart_test_tools_builder.dart';
import '../../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../../types/container.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/build_flatpak_bundle_builder.dart';

final class FlatpakMatrix extends Matrix<FlatpakArchMatrixSelector> {
  const FlatpakMatrix() : super(FlatpakArchMatrixSelector.values);

  ArchMatrixProperty get arch => const ArchMatrixProperty();

  QEmuArchProperty get qemuArch => const QEmuArchProperty();

  @override
  IMatrixProperty<FlatpakArchMatrixSelector> get selectorProperty => arch;

  @override
  List<IMatrixProperty<FlatpakArchMatrixSelector>> get includeProperties =>
      [arch, qemuArch];
}

final class BuildLinuxJobBuilder extends SdkJobBuilder
    with
        DartSdkJobBuilderMixin,
        MatrixJobBuilderMixin<FlatpakMatrix, FlatpakArchMatrixSelector> {
  @override
  final Expression dartSdkVersion;
  final Expression flatpakPlatformImage;
  final Expression flatpakSdkVersion;
  final Expression bundleName;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildNumberArgs;
  final Expression manifestPath;
  final Expression gpgKeyId;
  final Expression gpgKey;

  BuildLinuxJobBuilder({
    required this.dartSdkVersion,
    required this.flatpakPlatformImage,
    required this.flatpakSdkVersion,
    required this.bundleName,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildNumberArgs,
    required this.manifestPath,
    required this.gpgKeyId,
    required this.gpgKey,
  }) : matrix = const FlatpakMatrix();

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
          image: 'bilelmoussaoui/$flatpakPlatformImage',
          options: '--privileged',
        ),
        environment: Environments.flatpak,
        steps: [
          ...buildSetupSdkSteps(),
          ...const InstallDartTestToolsBuilder().build(),
          ...BuildFlatpakBundleBuilder(
            sdkVersion: flatpakSdkVersion,
            bundleName: bundleName,
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildNumberArgs: buildNumberArgs,
            manifestPath: manifestPath,
            gpgKeyId: gpgKeyId,
            gpgKey: gpgKey,
            arch: matrix.arch,
            qemuArch: matrix.qemuArch,
          ).build(),
        ],
      );
}
