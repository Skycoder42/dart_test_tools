import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import '../jobs/common_integration_test_config.dart';
import 'prepare_integration_test_builder.dart';

base mixin DesktopIntegrationTestConfig
    on JobConfig, CommonIntegrationTestConfig {}

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

  final DesktopIntegrationTestConfig config;
  final PlatformMatrixProperty platform;
  final TestArgsMatrixProperty testArgs;
  final RunPrefixMatrixProperty runPrefix;

  const DesktopIntegrationTestBuilder({
    required this.config,
    required this.platform,
    required this.testArgs,
    required this.runPrefix,
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
          config: config,
          platform: ExpressionOrValue.expression(platform.expression),
        ).build(),
        Step.run(
          name: 'Run integration tests',
          run: '${runPrefix.expression} '
              '${config.baseTool} test ${testArgs.expression} '
              '--reporter expanded '
              '${config.integrationTestPaths} || [ \$? = 79 ]',
          workingDirectory: config.integrationTestWorkingDirectory,
          shell: 'bash',
        ),
      ];
}
