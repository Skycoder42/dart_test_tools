import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../dart/dart_platform.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/compile_builder.dart';

final class _CompileMatrix extends PlatformMatrix {
  const _CompileMatrix() : super(DartPlatform.values);

  BinaryTypeMatrixProperty get binaryType => const BinaryTypeMatrixProperty();

  CompileArgsMatrixProperty get compileArgs =>
      const CompileArgsMatrixProperty();

  ArchiveTypeMatrixProperty get archiveType =>
      const ArchiveTypeMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
        ...super.includeProperties,
        binaryType,
        compileArgs,
        archiveType,
      ];
}

final class CompileJobBuilder extends SdkJobBuilder
    with
        DartSdkJobBuilderMixin,
        MatrixJobBuilderMixin<_CompileMatrix, IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<_CompileMatrix> {
  @override
  JobId get id => const JobId('compile');

  @override
  final Expression enabledPlatforms;
  @override
  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression archivePrefix;

  const CompileJobBuilder({
    required this.enabledPlatforms,
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.archivePrefix,
  }) : matrix = const _CompileMatrix();

  @override
  final _CompileMatrix matrix;

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Create compiled artifacts',
        permissions: const {
          'contents': 'read',
        },
        runsOn: runsOn,
        steps: [
          ...buildSetupSdkSteps(),
          ...CompileBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            archivePrefix: archivePrefix,
            platform: matrix.platform,
            binaryType: matrix.binaryType,
            compileArgs: matrix.compileArgs,
            archiveType: matrix.archiveType,
            pubTool: pubTool,
            runTool: runTool,
          ).build()
        ],
      );
}
