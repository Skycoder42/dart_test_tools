import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/contexts.dart';
import '../../common/environments.dart';
import '../../common/inputs.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/packagecloud_upload_builder.dart';

final class UploadDebJobConfig extends JobConfig with PackagecloudUploadConfig {
  late final ubuntuVersions = inputContext(WorkflowInputs.ubuntuVersions);

  UploadDebJobConfig(super.inputContext, super.secretContext);
}

final class UploadDebMatrix extends ExpressionMatrix<UbuntuCodeName> {
  UploadDebMatrix(super.expression);

  CodeNameMatrixProperty get codeName => const CodeNameMatrixProperty();

  @override
  IMatrixProperty<UbuntuCodeName> get selectorProperty => codeName;
}

final class UploadDebJobBuilder
    with MatrixJobBuilderMixin<UploadDebMatrix, UbuntuCodeName>
    implements JobBuilder {
  final JobId packageJobId;
  final UploadDebJobConfig config;

  UploadDebJobBuilder({required this.packageJobId, required this.config})
    : matrix = UploadDebMatrix(Functions.fromJson(config.ubuntuVersions));

  @override
  JobId get id => const JobId('upload_deb');

  @override
  Expression get matrixRunsOn => Expression.fake(RunsOn.ubuntuLatest.id);

  @override
  final UploadDebMatrix matrix;

  @override
  Job buildGeneric(String runsOn) => Job(
    name: 'Upload deb package to packagecloud',
    runsOn: runsOn,
    needs: {packageJobId},
    environment: Environments.packagecloud,
    steps: [
      ...PackagecloudUploadBuilder(
        config: config,
        codeName: matrix.codeName,
      ).build(),
    ],
  );
}
