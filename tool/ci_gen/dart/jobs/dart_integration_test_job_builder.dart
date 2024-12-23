import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../dart_platform.dart';
import '../steps/dart_integration_test_builder.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartIntegrationTestJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        DartIntegrationTestConfig,
        DartSdkJobConfig {
  DartIntegrationTestJobConfig(super.inputContext, super.secretContext);
}

final class DartIntegrationTestMatrix extends PlatformMatrix {
  const DartIntegrationTestMatrix() : super(DartPlatform.values);

  DartTestArgsMatrixProperty get dartTestArgs =>
      const DartTestArgsMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
        ...super.includeProperties,
        dartTestArgs,
      ];
}

final class DartIntegrationTestJobBuilder
    extends SdkJobBuilder<DartIntegrationTestJobConfig>
    with
        DartSdkJobBuilderMixin<DartIntegrationTestJobConfig>,
        MatrixJobBuilderMixin<DartIntegrationTestMatrix,
            IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<DartIntegrationTestMatrix> {
  final JobIdOutput enabledPlatformsOutput;

  @override
  final DartIntegrationTestMatrix matrix;

  DartIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required super.config,
  }) : matrix = const DartIntegrationTestMatrix();

  @override
  JobId get id => const JobId('integration_tests');

  @override
  Expression get enabledPlatforms => enabledPlatformsOutput.expression;

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Integration tests',
        ifExpression: config.integrationTestPaths.ne(Expression.empty),
        needs: {
          enabledPlatformsOutput.jobId,
        },
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
