import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../flutter_platform.dart';
import '../steps/desktop_integration_test_builder.dart';
import 'common_integration_test_config.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class DesktopIntegrationTestJobConfig
    extends CommonIntegrationTestJobConfig
    with DesktopIntegrationTestConfig {
  DesktopIntegrationTestJobConfig(super.inputContext, super.secretContext);
}

final class FlutterIntegrationTestMatrix extends PlatformMatrix {
  const FlutterIntegrationTestMatrix() : super(FlutterPlatform.desktop);

  TestArgsMatrixProperty get testArgs => const TestArgsMatrixProperty();

  RunPrefixMatrixProperty get runPrefix => const RunPrefixMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
    ...super.includeProperties,
    testArgs,
    runPrefix,
  ];
}

final class DesktopIntegrationTestJobBuilder
    extends SdkJobBuilder<DesktopIntegrationTestJobConfig>
    with
        FlutterSdkJobBuilderMixin<DesktopIntegrationTestJobConfig>,
        MatrixJobBuilderMixin<
          FlutterIntegrationTestMatrix,
          IPlatformMatrixSelector
        >,
        PlatformJobBuilderMixin<FlutterIntegrationTestMatrix> {
  final JobIdOutput enabledPlatformsOutput;

  DesktopIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required super.config,
  }) : matrix = const FlutterIntegrationTestMatrix();

  @override
  JobId get id => const JobId('integration_tests_desktop');

  @override
  Expression get enabledPlatforms => enabledPlatformsOutput.expression;

  @override
  final FlutterIntegrationTestMatrix matrix;

  @override
  Job buildGeneric(String runsOn) => Job(
    name: 'Integration tests (desktop)',
    ifExpression: config.integrationTestPaths.ne(Expression.empty),
    needs: {enabledPlatformsOutput.jobId},
    runsOn: runsOn,
    steps: [
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.expression(matrix.platform.expression),
      ),
      ...DesktopIntegrationTestBuilder(
        config: config,
        platform: matrix.platform,
        testArgs: matrix.testArgs,
        runPrefix: matrix.runPrefix,
      ).build(),
    ],
  );
}
