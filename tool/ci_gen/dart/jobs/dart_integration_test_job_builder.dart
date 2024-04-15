import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../dart_platform.dart';
import '../steps/dart_integration_test_builder.dart';
import 'dart_sdk_job_builder_mixin.dart';

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

final class DartIntegrationTestJobBuilder extends SdkJobBuilder
    with
        DartSdkJobBuilderMixin,
        MatrixJobBuilderMixin<DartIntegrationTestMatrix,
            IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<DartIntegrationTestMatrix> {
  final JobIdOutput enabledPlatformsOutput;
  @override
  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestEnvVars;
  final Expression integrationTestCacheConfig;

  @override
  final DartIntegrationTestMatrix matrix;

  DartIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestEnvVars,
    required this.integrationTestCacheConfig,
  }) : matrix = const DartIntegrationTestMatrix();

  @override
  JobId get id => const JobId('integration_tests');

  @override
  Expression get enabledPlatforms => enabledPlatformsOutput.expression;

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Integration tests',
        ifExpression: integrationTestPaths.ne(Expression.empty),
        needs: {
          enabledPlatformsOutput.jobId,
        },
        runsOn: runsOn,
        steps: [
          ...buildSetupSdkSteps(),
          ...DartIntegrationTestBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestEnvVars: integrationTestEnvVars,
            integrationTestCacheConfig: integrationTestCacheConfig,
            platform: matrix.platform,
            dartTestArgs: matrix.dartTestArgs,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
