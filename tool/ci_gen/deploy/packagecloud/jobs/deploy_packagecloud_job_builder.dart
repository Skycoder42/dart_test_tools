import '../../../common/api/job_builder.dart';
import '../../../common/api/job_config.dart';
import '../../../common/api/matrix_job_builder_mixin.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/contexts.dart';
import '../../../common/environments.dart';
import '../../../common/inputs.dart';
import '../../../common/steps/resolve_artifact_prefix_builder.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/job.dart';
import '../../../types/runs_on.dart';
import '../steps/packagecloud_upload_builder.dart';

final class DeployPackagecloudJobConfig extends JobConfig
    with
        WorkingDirectoryConfig,
        ResolveArtifactPrefixConfig,
        PackagecloudUploadConfig {
  late final ubuntuVersions = inputContext(WorkflowInputs.ubuntuVersions);

  DeployPackagecloudJobConfig(super.inputContext, super.secretContext);
}

final class DeployPackagecloudMatrix extends ExpressionMatrix<UbuntuCodeName> {
  DeployPackagecloudMatrix(super.expression);

  CodeNameMatrixProperty get codeName => const CodeNameMatrixProperty();

  @override
  IMatrixProperty<UbuntuCodeName> get selectorProperty => codeName;
}

final class DeployPackagecloudJobBuilder
    with MatrixJobBuilderMixin<DeployPackagecloudMatrix, UbuntuCodeName>
    implements JobBuilder {
  final DeployPackagecloudJobConfig config;

  DeployPackagecloudJobBuilder({required this.config})
    : matrix = DeployPackagecloudMatrix(
        Functions.fromJson(config.ubuntuVersions),
      );

  @override
  JobId get id => const JobId('deploy_packagecloud');

  @override
  Expression get matrixRunsOn => Expression.fake(RunsOn.ubuntuLatest.id);

  @override
  final DeployPackagecloudMatrix matrix;

  @override
  Job buildGeneric(String runsOn) => Job(
    name: 'Deploy deb package to packagecloud',
    runsOn: runsOn,
    environment: Environments.packagecloud,
    steps: [
      ...PackagecloudUploadBuilder(
        config: config,
        codeName: matrix.codeName,
      ).build(),
    ],
  );
}
