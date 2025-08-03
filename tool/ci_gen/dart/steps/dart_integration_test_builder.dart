import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../common/steps/cache_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin DartIntegrationTestConfig on JobConfig, ProjectSetupConfig {
  late final integrationTestSetup = inputContext(
    WorkflowInputs.integrationTestSetup,
  );
  late final integrationTestPaths = inputContext(
    WorkflowInputs.integrationTestPaths,
  );
  late final integrationTestEnvVars = secretContext(
    WorkflowSecrets.integrationTestEnvVars,
  );
  late final integrationTestCacheConfig = inputContext(
    WorkflowInputs.integrationTestCacheConfig,
  );

  @override
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);

  @override
  late final artifactDependencies = inputContext(
    WorkflowInputs.artifactDependencies,
  );
}

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

  final DartIntegrationTestConfig config;
  final PlatformMatrixProperty platform;
  final DartTestArgsMatrixProperty dartTestArgs;

  const DartIntegrationTestBuilder({
    required this.config,
    required this.platform,
    required this.dartTestArgs,
  });

  @override
  Iterable<Step> build() => [
    ...ProjectSetupBuilder(config: config).build(),
    ...CacheBuilder(
      cacheStepId: testSetupCacheStepId,
      platform: ExpressionOrValue.expression(platform.expression),
      cacheConfig: config.integrationTestCacheConfig,
      ifExpression: _platformTestSetup.ne(Expression.empty),
    ).build(),
    Step.run(
      name: 'Create .env file from secrets',
      run: "echo '${config.integrationTestEnvVars}' > .env",
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    Step.run(
      name: 'Run platform test setup',
      ifExpression: _platformTestSetup.ne(Expression.empty),
      run: _platformTestSetup.toString(),
      workingDirectory: config.workingDirectory.toString(),
      env: CacheBuilder.createEnv(testSetupCacheStepId),
    ),
    Step.run(
      name: 'Run integration tests',
      run:
          '${config.baseTool} test ${dartTestArgs.expression} '
          '--reporter github ${config.integrationTestPaths} '
          r'|| [ $? = 79 ]',
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    Step.run(
      name: 'Shred .env file',
      ifExpression: Functions.always,
      run: 'shred -fzvu .env',
      workingDirectory: config.workingDirectory.toString(),
    ),
  ];

  Expression get _platformTestSetup => Expression(
    'fromJSON(${config.integrationTestSetup.value})'
    '[${platform.expression.value}]',
  );
}
