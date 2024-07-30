import '../../common/api/step_builder.dart';
import '../../common/steps/cache_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class PrepareIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression integrationTestSetup;
  final Expression integrationTestProject;
  final Expression integrationTestCacheConfig;
  final ExpressionOrValue platform;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const PrepareIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
    required this.platform,
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
          removePubspecOverrides:
              ExpressionOrValue.expression(removePubspecOverrides),
          isFlutter: const ExpressionOrValue.value(true),
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Validate flutter setup',
          run: '$baseTool doctor -v',
        ),
        ...ProjectPrepareBuilder(
          titleSuffix: '(Integration test project)',
          workingDirectory:
              Expression.fake('$workingDirectory/$integrationTestProject'),
          removePubspecOverrides:
              ExpressionOrValue.expression(removePubspecOverrides),
          isFlutter: const ExpressionOrValue.value(false),
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: integrationTestProject.ne(Expression.empty),
        ).build(),
        ...CacheBuilder(
          cacheStepId: testSetupCacheStepId,
          platform: platform,
          cacheConfig: integrationTestCacheConfig,
          ifExpression: _platformTestSetup.ne(Expression.empty),
        ).build(),
        Step.run(
          name: 'Run platform test setup',
          ifExpression: _platformTestSetup.ne(Expression.empty),
          run: _platformTestSetup.toString(),
          workingDirectory: workingDirectory.toString(),
          env: CacheBuilder.createEnv(testSetupCacheStepId),
        ),
      ];

  Expression get _platformTestSetup => Expression(
        'fromJSON(${integrationTestSetup.value})'
        '[${platform.asExpression.value}]',
      );
}
