import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../dart_platform.dart';
import '../steps/dart_integration_test_builder.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartIntegrationTestJobConfig(
  super.inputContext,
  super.secretContext,
) extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        DartIntegrationTestConfig,
        DartSdkJobConfig {
  @override
  // ignore: overridden_fields to replace default value
  late final needsFlutterSdk = ExpressionOrValue.expression(
    inputContext(WorkflowInputs.needsFlutterSdk),
  );
}

final class const DartIntegrationTestMatrix() extends PlatformMatrix {
  this : super(DartPlatform.values);

  DartTestArgsMatrixProperty get dartTestArgs =>
      const DartTestArgsMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
    ...super.includeProperties,
    dartTestArgs,
  ];
}

final class DartIntegrationTestJobBuilder({
  required final JobIdOutput enabledPlatformsOutput,
  required super.config,
}) extends SdkJobBuilder<DartIntegrationTestJobConfig>
    with
        DartSdkJobBuilderMixin<DartIntegrationTestJobConfig>,
        MatrixJobBuilderMixin<
          DartIntegrationTestMatrix,
          IPlatformMatrixSelector
        >,
        PlatformJobBuilderMixin<DartIntegrationTestMatrix> {
  @override
  final DartIntegrationTestMatrix matrix;

  this : matrix = const DartIntegrationTestMatrix();

  @override
  JobId get id => const JobId('integration_tests');

  @override
  Expression get enabledPlatforms => enabledPlatformsOutput.expression;

  @override
  Job buildGeneric(String runsOn) => Job(
    name: 'Integration tests',
    ifExpression: config.integrationTestPaths.ne(Expression.empty),
    needs: {enabledPlatformsOutput.jobId},
    runsOn: runsOn,
    steps: [
      ...buildSetupSdkSteps(),
      ...DartIntegrationTestBuilder(
        config: config,
        platform: matrix.platform,
        dartTestArgs: matrix.dartTestArgs,
      ).build(),
    ],
  );
}
