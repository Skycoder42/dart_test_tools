import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
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

  const IosIntegrationTestBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...PrepareIntegrationTestBuilder(
      config: config,
      platform: ExpressionOrValue.value(FlutterPlatform.ios.platform),
    ).build(),
    ...InstallXcodeSigningBuilder(config: config).build(),
    ...SetupGCloudBuilder(config: config).build(),
    const Step.run(
      name: 'Select FTL-supported Xcode',
      shell: 'bash',
      run: r'''
set -eo pipefail
xcode_version="$(gcloud firebase test ios versions list --format=json | jq -r '.[] | select(.tags | index("default")) | .supportedXcodeVersionIds | max_by(split(".") | map(tonumber))')"
sudo xcode-select -s "/Applications/Xcode_${xcode_version}.app"
''',
    ),
    const Step.run(
      name: 'Log supported FTL Xcode versions',
      ifExpression: Functions.failure,
      run: 'gcloud firebase test ios versions list',
    ),
    Step.run(
      name: 'Build integration test app',
      run:
          '${config.baseTool} build ios '
          "--release --config-only '${config.integrationTestPaths}'",
      workingDirectory: config.integrationTestWorkingDirectory,
    ),
    Step.run(
      name: 'Build test instrumentation app',
      run:
          'xcodebuild build-for-testing '
          '-workspace Runner.xcworkspace '
          '-scheme Runner '
          '-configuration Release '
          '-sdk iphoneos '
          '-derivedDataPath ../build/ios_integration',
      workingDirectory: '${config.integrationTestWorkingDirectory}/ios',
    ),
    Step.run(
      name: 'Create integration test package',
      run:
          'zip -r --must-match app-release.zip '
          'Release-iphoneos *.xctestrun',
      workingDirectory:
          '${config.integrationTestWorkingDirectory}/build/ios_integration/Build/Products',
    ),
    Step.run(
      name: 'Run integration tests',
      run:
          'gcloud firebase test ios run '
          '--type xctest '
          '--test build/ios_integration/Build/Products/app-release.zip',
      workingDirectory: config.integrationTestWorkingDirectory,
    ),
  ];
}
