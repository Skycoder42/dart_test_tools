import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/steps/cache_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin PrepareIntegrationTestConfig on ProjectSetupConfig {
  late Expression integrationTestSetup;
  late Expression integrationTestProject;
  late Expression integrationTestCacheConfig;
  late String baseTool;

  String get integrationTestWorkingDirectory =>
      '$workingDirectory/$integrationTestProject';

  @override
  void expand() {
    isFlutter = const ExpressionOrValue.value(true);
    super.expand();
  }
}

final class _TestProjectConfig extends JobConfig
    with UpdateOverridesConfig, ProjectPrepareConfig {
  _TestProjectConfig(PrepareIntegrationTestConfig baseConfig) {
    workingDirectory = Expression.fake(
      '${baseConfig.workingDirectory}/${baseConfig.integrationTestProject}',
    );
    removePubspecOverrides = baseConfig.removePubspecOverrides;
    localResolution = const ExpressionOrValue.value(false);
    isFlutter = const ExpressionOrValue.value(false);
    pubTool = baseConfig.pubTool;
    runTool = baseConfig.runTool;
    ifExpression = baseConfig.integrationTestProject.ne(Expression.empty);
  }
}

class PrepareIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final ExpressionOrValue platform;
  final PrepareIntegrationTestConfig config;

  const PrepareIntegrationTestBuilder({
    required this.platform,
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(config: config).build(),
        Step.run(
          name: 'Validate flutter setup',
          run: '${config.baseTool} doctor -v',
        ),
        ...ProjectPrepareBuilder(
          titleSuffix: '(Integration test project)',
          config: _TestProjectConfig(config),
        ).build(),
        ...CacheBuilder(
          cacheStepId: testSetupCacheStepId,
          platform: platform,
          cacheConfig: config.integrationTestCacheConfig,
          ifExpression: _platformTestSetup.ne(Expression.empty),
        ).build(),
        Step.run(
          name: 'Run platform test setup',
          ifExpression: _platformTestSetup.ne(Expression.empty),
          run: _platformTestSetup.toString(),
          workingDirectory: config.workingDirectory.toString(),
          env: CacheBuilder.createEnv(testSetupCacheStepId),
        ),
      ];

  Expression get _platformTestSetup => Expression(
        'fromJSON(${config.integrationTestSetup.value})'
        '[${platform.asExpression.value}]',
      );
}
