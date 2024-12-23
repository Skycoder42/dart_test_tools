import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import '../jobs/common_integration_test_config.dart';
import 'install_xcode_signing_builder.dart';
import 'prepare_integration_test_builder.dart';
import 'setup_gcloud_builder.dart';

base mixin IosIntegrationTestConfig
    on
        JobConfig,
        CommonIntegrationTestConfig,
        InstallXcodeSigningConfig,
        SetupGCloudConfig {}

class IosIntegrationTestBuilder implements StepBuilder {
  static const testSetupCacheStepId = StepId('test-setup-cache');

  final IosIntegrationTestConfig config;

  const IosIntegrationTestBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        ...PrepareIntegrationTestBuilder(
          config: config,
          platform: ExpressionOrValue.value(FlutterPlatform.ios.platform),
        ).build(),
        ...InstallXcodeSigningBuilder(config: config).build(),
        Step.run(
          name: 'Build integration test app',
          run: '${config.baseTool} build ios '
              "--release '${config.integrationTestPaths}'",
          workingDirectory: config.integrationTestWorkingDirectory,
        ),
        Step.run(
          name: 'Build test instrumentation app',
          run: 'xcodebuild build-for-testing '
              '-workspace Runner.xcworkspace '
              '-scheme Runner '
              '-configuration Release '
              '-sdk iphoneos '
              '-derivedDataPath ../build/ios_integration',
          workingDirectory: '${config.integrationTestWorkingDirectory}/ios',
        ),
        Step.run(
          name: 'Create integration test package',
          run: 'zip -r --must-match app-release.zip '
              'Release-iphoneos *.xctestrun',
          workingDirectory:
              '${config.integrationTestWorkingDirectory}/build/ios_integration/Build/Products',
        ),
        ...SetupGCloudBuilder(config: config).build(),
        Step.run(
          name: 'Run integration tests',
          run: 'gcloud firebase test ios run '
              '--type xctest '
              '--test build/ios_integration/Build/Products/app-release.zip',
          workingDirectory: config.integrationTestWorkingDirectory,
        ),
      ];
}
