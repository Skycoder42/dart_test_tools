import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'prepare_integration_test_builder.dart';

final class TestArgsMatrixProperty extends IMatrixProperty<FlutterPlatform> {
  const TestArgsMatrixProperty();

  @override
  String get name => 'testArgs';

  @override
  Object? valueFor(FlutterPlatform selector) => switch (selector) {
        FlutterPlatform.linux => '-d linux',
        FlutterPlatform.macos => '-d macos',
        FlutterPlatform.windows => '-d windows',
        _ => null,
      };
}

final class RunPrefixMatrixProperty extends IMatrixProperty<FlutterPlatform> {
  const RunPrefixMatrixProperty();

  @override
  String get name => 'runPrefix';

  @override
  Object? valueFor(FlutterPlatform selector) => switch (selector) {
        FlutterPlatform.linux => 'xvfb-run --auto-servernum',
        _ => null,
      };
}

class DesktopIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestProject;
  final Expression integrationTestCacheConfig;
  final PlatformMatrixProperty platform;
  final TestArgsMatrixProperty testArgs;
  final RunPrefixMatrixProperty runPrefix;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const DesktopIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
    required this.platform,
    required this.testArgs,
    required this.runPrefix,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install test dependencies (linux)',
          ifExpression:
              platform.expression.eq(const Expression.literal('linux')),
          run: '''
set -e
sudo apt-get -qq update
sudo apt-get -qq install ninja-build libgtk-3-dev xvfb
''',
        ),
        ...PrepareIntegrationTestBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          removePubspecOverrides: removePubspecOverrides,
          integrationTestSetup: integrationTestSetup,
          integrationTestProject: integrationTestProject,
          integrationTestCacheConfig: integrationTestCacheConfig,
          platform: ExpressionOrValue.expression(platform.expression),
          baseTool: baseTool,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Run integration tests',
          run: '${runPrefix.expression} '
              '$baseTool test ${testArgs.expression} '
              '--reporter expanded $integrationTestPaths || [ \$? = 79 ]',
          workingDirectory: '$workingDirectory/$integrationTestProject',
          shell: 'bash',
        ),
      ];
}
