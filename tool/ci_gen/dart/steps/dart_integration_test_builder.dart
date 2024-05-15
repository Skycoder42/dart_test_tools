import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/steps/cache_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

final class DartTestArgsMatrixProperty
    extends IMatrixProperty<IPlatformMatrixSelector> {
  const DartTestArgsMatrixProperty();

  @override
  String get name => 'dartTestArgs';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
        IPlatformMatrixSelector(isWeb: true) => '-p chrome',
        _ => null,
      };
}

class DartIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestEnvVars;
  final Expression integrationTestCacheConfig;
  final PlatformMatrixProperty platform;
  final DartTestArgsMatrixProperty dartTestArgs;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const DartIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestEnvVars,
    required this.integrationTestCacheConfig,
    required this.platform,
    required this.dartTestArgs,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          removePubspecOverrides: removePubspecOverrides,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        ...CacheBuilder(
          cacheStepId: testSetupCacheStepId,
          platform: platform.expression,
          cacheConfig: integrationTestCacheConfig,
          ifExpression: _platformTestSetup.ne(Expression.empty),
        ).build(),
        Step.run(
          name: 'Create .env file from secrets',
          run: "echo '$integrationTestEnvVars' > .env",
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.run(
          name: 'Run platform test setup',
          ifExpression: _platformTestSetup.ne(Expression.empty),
          run: _platformTestSetup.toString(),
          workingDirectory: workingDirectory.toString(),
          env: CacheBuilder.createEnv(testSetupCacheStepId),
        ),
        Step.run(
          name: 'Run integration tests',
          run: '$baseTool test ${dartTestArgs.expression} '
              '--reporter github $integrationTestPaths || [ \$? = 79 ]',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.run(
          name: 'Shred .env file',
          ifExpression: Functions.always,
          run: 'shred -fzvu .env',
          workingDirectory: workingDirectory.toString(),
        ),
      ];

  Expression get _platformTestSetup => Expression(
        'fromJSON(${integrationTestSetup.value})[${platform.expression.value}]',
      );
}
