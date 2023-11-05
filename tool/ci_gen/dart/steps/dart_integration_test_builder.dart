import '../../common/api/step_builder.dart';
import '../../common/steps/cache_builder.dart';
import '../../common/steps/platforms_builder_mixin.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

abstract interface class IDartIntegrationTestMatrix {
  Expression get platform;
  Expression get dartTestArgs;
}

class DartIntegrationTestBuilder
    with PlatformsBuilderMixin
    implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestEnvVars;
  final Expression integrationTestCacheConfig;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final IDartIntegrationTestMatrix matrix;

  const DartIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestEnvVars,
    required this.integrationTestCacheConfig,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
    required this.matrix,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          pubTool: pubTool,
          runTool: runTool,
          withPlatform: matrix.platform,
        ).build(),
        ...CacheBuilder(
          cacheStepId: testSetupCacheStepId,
          platform: matrix.platform,
          cacheConfig: integrationTestCacheConfig,
          ifExpression:
              _platformTestSetup.ne(Expression.empty) & shouldRunExpression,
        ).build(),
        Step.run(
          name: 'Create .env file from secrets',
          ifExpression: shouldRunExpression,
          run: "echo '$integrationTestEnvVars' > .env",
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.run(
          name: 'Run platform test setup',
          ifExpression:
              _platformTestSetup.ne(Expression.empty) & shouldRunExpression,
          run: _platformTestSetup.toString(),
          workingDirectory: workingDirectory.toString(),
          env: CacheBuilder.createEnv(testSetupCacheStepId),
        ),
        Step.run(
          name: 'Run integration tests',
          ifExpression: shouldRunExpression,
          run: '$baseTool test ${matrix.dartTestArgs} '
              '--reporter github $integrationTestPaths',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Shred .env file',
          ifExpression: const Expression('always()') & shouldRunExpression,
          run: 'shred -fzvu .env',
          workingDirectory: workingDirectory.toString(),
        ),
      ];

  Expression get _platformTestSetup => Expression(
        'fromJSON(${integrationTestSetup.value})[${matrix.platform.value}]',
      );
}
