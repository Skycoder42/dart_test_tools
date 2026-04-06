import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../dart/dart_platform.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/compile_builder.dart';

final class CompileJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        CompileConfig,
        DartSdkJobConfig {
  CompileJobConfig(super.inputContext, super.secretContext);
}

final class CompileMatrix extends PlatformMatrix {
  CompileMatrix() : super(DartPlatform.values.where((p) => !p.isWeb).toList());

  ExecutableSuffixProperty get executableSuffix =>
      const ExecutableSuffixProperty();

  ArchiveTypeMatrixProperty get archiveType =>
      const ArchiveTypeMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
    ...super.includeProperties,
    executableSuffix,
    archiveType,
  ];
}

final class CompileJobBuilder extends SdkJobBuilder<CompileJobConfig>
    with
        DartSdkJobBuilderMixin<CompileJobConfig>,
        MatrixJobBuilderMixin<CompileMatrix, IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<CompileMatrix> {
  @override
  JobId get id => const JobId('compile');

  @override
  final Expression enabledPlatforms;

  CompileJobBuilder({required this.enabledPlatforms, required super.config})
    : matrix = CompileMatrix();

  @override
  final CompileMatrix matrix;

  @override
  Job buildGeneric(String runsOn) => Job(
    name: 'Create compiled artifacts',
    permissions: const {'contents': 'read'},
    runsOn: runsOn,
    steps: [
      ...buildSetupSdkSteps(),
      ...CompileBuilder(
        config: config,
        platform: matrix.platform,
        executableSuffix: matrix.executableSuffix,
        archiveType: matrix.archiveType,
      ).build(),
    ],
  );
}
