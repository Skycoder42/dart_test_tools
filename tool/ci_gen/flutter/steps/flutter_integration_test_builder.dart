import '../../common/api/step_builder.dart';
import '../../common/steps/platforms_builder_mixin.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

abstract class IFlutterIntegrationTestMatrix {
  Expression get platform;
  Expression get testDevice;
  Expression get runPrefix;
  Expression get desktop;
}

class FlutterIntegrationTestBuilder
    with PlatformsBuilderMixin
    implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestProject;
  @override
  final Expression platforms;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final IFlutterIntegrationTestMatrix matrix;

  const FlutterIntegrationTestBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.platforms,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
    required this.matrix,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install test dependencies (linux)',
          ifExpression: matrix.platform.eq(const Expression.literal('linux')) &
              _shouldRun,
          run: 'sudo apt-get -qq install ninja-build libgtk-3-dev xvfb',
        ),
        Step.run(
          name: 'Enable experimental platforms',
          ifExpression: matrix.desktop,
          run: 'flutter config --enable-${matrix.platform}-desktop',
        ),
        Step.run(
          name: 'Validate flutter setup',
          ifExpression: _shouldRun,
          run: 'flutter doctor -v',
        ),
        ...ProjectSetupBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: _shouldRun,
        ).build(),
        ...ProjectPrepareBuilder(
          titleSuffix: '(Integration test project)',
          workingDirectory:
              Expression.fake('$workingDirectory/$integrationTestProject'),
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: _shouldRun &
              integrationTestProject.ne(const Expression.literal('')),
        ).build(),
        Step.run(
          name: 'Run platform test setup',
          ifExpression:
              _platformTestSetup.ne(const Expression.literal('')) & _shouldRun,
          run: _platformTestSetup.toString(),
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Run integration tests (dart-vm)',
          ifExpression:
              matrix.platform.ne(const Expression.literal('web')) & _shouldRun,
          run: '${matrix.runPrefix} '
              '$baseTool test ${matrix.testDevice} $integrationTestPaths',
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
        Step.run(
          name: 'Run integration tests (web)',
          ifExpression:
              matrix.platform.eq(const Expression.literal('web')) & _shouldRun,
          run: '\$Env:CHROMEWEBDRIVER\\chromedriver --port=4444 & ; '
              '$baseTool drive '
              '--driver=test_driver/integration_test.dart '
              '--target=$integrationTestPaths '
              '--release '
              '-d chrome --browser-name=chrome',
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
      ];

  Expression get _shouldRun => shouldRunExpression(matrix.platform);

  Expression get _platformTestSetup => Expression(
        'fromJSON(${integrationTestSetup.value})[${matrix.platform.value}]',
      );
}
