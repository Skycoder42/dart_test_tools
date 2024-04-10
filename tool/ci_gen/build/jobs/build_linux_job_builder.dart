import '../../common/api/job_builder.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/environments.dart';
import '../../types/container.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/build_flatpak_bundle_builder.dart';

final class _FlatpakMatrix extends Matrix<FlatpakArchMatrixSelector> {
  const _FlatpakMatrix() : super(FlatpakArchMatrixSelector.values);

  ArchMatrixProperty get arch => const ArchMatrixProperty();

  QEmuArchProperty get qemuArch => const QEmuArchProperty();

  @override
  IMatrixProperty<FlatpakArchMatrixSelector> get selectorProperty => arch;

  @override
  List<IMatrixProperty<FlatpakArchMatrixSelector>> get includeProperties =>
      [arch, qemuArch];
}

final class BuildLinuxJobBuilder
    with MatrixJobBuilderMixin<_FlatpakMatrix, FlatpakArchMatrixSelector>
    implements JobBuilder {
  final Expression sdkVersion;
  final Expression bundleName;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression manifestPath;

  const BuildLinuxJobBuilder({
    required this.sdkVersion,
    required this.bundleName,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.manifestPath,
  }) : matrix = const _FlatpakMatrix();

  @override
  JobId get id => const JobId('build_linux');

  @override
  final _FlatpakMatrix matrix;

  @override
  Expression get matrixRunsOn => Expression.fake(RunsOn.ubuntuLatest.id);

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Build linux flatpak bundle',
        runsOn: runsOn,
        container: Container(
          image:
              'bilelmoussaoui/flatpak-github-actions:freedesktop-$sdkVersion',
          options: '--privileged',
        ),
        environment: Environments.flatpak,
        steps: [
          ...BuildFlatpakBundleBuilder(
            sdkVersion: sdkVersion,
            bundleName: bundleName,
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            manifestPath: manifestPath,
            flutterSdkGpgKey: Expression('env.FLUTTER_SDK_GPG_KEY'),
            arch: matrix.arch,
            qemuArch: matrix.qemuArch,
          ).build(),
        ],
      );
}
