import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../flutter_platform.dart';
import '../steps/flutter_integration_test_builder.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class DesktopMatrixProperty extends IMatrixProperty<FlutterPlatform> {
  const DesktopMatrixProperty();

  @override
  String get name => 'desktop';

  @override
  Object? valueFor(FlutterPlatform selector) => switch (selector) {
        FlutterPlatform.linux ||
        FlutterPlatform.macos ||
        FlutterPlatform.windows =>
          true,
        _ => null,
      };
}

final class FlutterIntegrationTestMatrix extends PlatformMatrix {
  const FlutterIntegrationTestMatrix() : super(FlutterPlatform.values);

  TestArgsMatrixProperty get testArgs => const TestArgsMatrixProperty();

  RunPrefixMatrixProperty get runPrefix => const RunPrefixMatrixProperty();

  DesktopMatrixProperty get desktop => const DesktopMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
        ...super.includeProperties,
        testArgs,
        runPrefix,
        desktop,
      ];
}

final class FlutterIntegrationTestJobBuilder extends SdkJobBuilder
    with
        FlutterSdkJobBuilderMixin,
        MatrixJobBuilderMixin<FlutterIntegrationTestMatrix,
            IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<FlutterIntegrationTestMatrix> {
  final JobIdOutput enabledPlatformsOutput;
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestProject;
  final Expression integrationTestCacheConfig;
  final Expression androidAVDImage;
  final Expression androidAVDDevice;

  FlutterIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
    required this.androidAVDImage,
    required this.androidAVDDevice,
  }) : matrix = const FlutterIntegrationTestMatrix();

  @override
  JobId get id => const JobId('integration_tests');

  @override
  Expression get enabledPlatforms => enabledPlatformsOutput.expression;

  @override
  final FlutterIntegrationTestMatrix matrix;

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Integration tests',
        ifExpression: integrationTestPaths.ne(Expression.empty),
        needs: {
          enabledPlatformsOutput.jobId,
        },
        runsOn: runsOn,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform:
                ExpressionOrValue.expression(matrix.platform.expression),
            enableDesktopCondition: matrix.desktop.expression,
          ),
          ...FlutterIntegrationTestBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestProject: integrationTestProject,
            integrationTestCacheConfig: integrationTestCacheConfig,
            androidAVDImage: androidAVDImage,
            androidAVDDevice: androidAVDDevice,
            platform: matrix.platform,
            testArgs: matrix.testArgs,
            runPrefix: matrix.runPrefix,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}
