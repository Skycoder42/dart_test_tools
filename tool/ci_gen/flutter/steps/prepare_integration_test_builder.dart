import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/cache_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin PrepareIntegrationTestConfig on ProjectSetupConfig {
  late final integrationTestSetup = inputContext(
    WorkflowInputs.integrationTestSetup,
  );
  late final integrationTestProject = inputContext(
    WorkflowInputs.integrationTestProject,
  );
  late final integrationTestCacheConfig = inputContext(
    WorkflowInputs.integrationTestCacheConfig,
  );

  String get integrationTestWorkingDirectory =>
      '$workingDirectory/$integrationTestProject';
}

final class _TestProjectConfig extends JobConfig
    with SdkJobConfig, WorkingDirectoryConfig, ProjectPrepareConfig {
  final PrepareIntegrationTestConfig baseConfig;

  @override
  late final isFlutter = const ExpressionOrValue.value(false);

  @override
  String get baseTool => baseConfig.baseTool;

  @override
  String get pubTool => baseConfig.pubTool;

  @override
  String get runTool => baseConfig.runTool;

  @override
  // ignore: overridden_fields
  late final workingDirectory = Expression.fake(
    '${baseConfig.workingDirectory}/${baseConfig.integrationTestProject}',
  );

  @override
  bool get withBuildRunner => false;

  @override
  late final ifExpression = baseConfig.integrationTestProject.ne(
    Expression.empty,
  );

  _TestProjectConfig(this.baseConfig)
    : super(baseConfig.inputContext, baseConfig.secretContext);
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
