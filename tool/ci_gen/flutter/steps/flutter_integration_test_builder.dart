import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../common/steps/cache_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';

final class TestArgsMatrixProperty extends IMatrixProperty<FlutterPlatform> {
  const TestArgsMatrixProperty();

  @override
  String get name => 'testArgs';

  @override
  Object? valueFor(FlutterPlatform selector) => switch (selector) {
        FlutterPlatform.android || FlutterPlatform.ios => '--timeout 3x',
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

class FlutterIntegrationTestBuilder implements StepBuilder {
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
  final Expression androidAVDImage;
  final Expression androidAVDDevice;
  final PlatformMatrixProperty platform;
  final TestArgsMatrixProperty testArgs;
  final RunPrefixMatrixProperty runPrefix;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const FlutterIntegrationTestBuilder({
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
    required this.platform,
    required this.testArgs,
    required this.runPrefix,
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
          name: 'Install test dependencies (android)',
          ifExpression:
              platform.expression.eq(const Expression.literal('android')),
          run: '''
set -ex
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH"
printf 'y\\n%.0s' {1..10} | sdkmanager --licenses
sdkmanager --install emulator '$androidAVDImage'
avdmanager create avd \\
  --force \\
  --name default \\
  --package '$androidAVDImage' \\
  --device '$androidAVDDevice'
''',
        ),
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
          platform: platform.expression,
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
        Step.run(
          name: 'Start Android-Emulator',
          ifExpression:
              platform.expression.eq(const Expression.literal('android')),
          run: '''
set -ex
nohup \$ANDROID_HOME/emulator/emulator -no-metrics -no-snapstorage -no-snapshot -no-audio -no-boot-anim -no-window @default &
\$ANDROID_HOME/platform-tools/adb wait-for-device shell 'while [[ -z \$(getprop sys.boot_completed | tr -d '\\r') ]]; do sleep 1; done; input keyevent 82'
$baseTool devices
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Start iOS-Simulator',
          ifExpression: platform.expression.eq(const Expression.literal('ios')),
          run: '''
set -e
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
$baseTool devices
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Run integration tests (dart-vm)',
          ifExpression: platform.expression.ne(const Expression.literal('web')),
          run: '${runPrefix.expression} '
              '$baseTool test ${testArgs.expression} '
              '--reporter expanded $integrationTestPaths || [ \$? = 79 ]',
          workingDirectory: '$workingDirectory/$integrationTestProject',
          shell: 'bash',
        ),
        Step.run(
          name: 'Run integration tests (web)',
          ifExpression: platform.expression.eq(const Expression.literal('web')),
          run: r'$ChromeWebDriver/chromedriver --port=4444 & '
              '$baseTool drive '
              '--driver test_driver/integration_test.dart '
              '--target $integrationTestPaths '
              '--release '
              '-d chrome --browser-name chrome '
              r'|| [ $? = 79 ]',
          workingDirectory: '$workingDirectory/$integrationTestProject',
          shell: 'bash',
        ),
      ];

  Expression get _platformTestSetup => Expression(
        'fromJSON(${integrationTestSetup.value})[${platform.expression.value}]',
      );
}
