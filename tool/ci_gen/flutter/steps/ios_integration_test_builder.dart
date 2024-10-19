import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'install_xcode_signing_builder.dart';
import 'prepare_integration_test_builder.dart';
import 'setup_gcloud_builder.dart';

class IosIntegrationTestBuilder implements StepBuilder {
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
  final Expression encodedProvisioningProfile;
  final Expression encodedSigningIdentity;
  final Expression signingIdentityPassphrase;
  final Expression firebaseProjectId;
  final Expression firebaseCredentials;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const IosIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
    required this.encodedProvisioningProfile,
    required this.encodedSigningIdentity,
    required this.signingIdentityPassphrase,
    required this.firebaseProjectId,
    required this.firebaseCredentials,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...PrepareIntegrationTestBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          removePubspecOverrides: removePubspecOverrides,
          integrationTestSetup: integrationTestSetup,
          integrationTestProject: integrationTestProject,
          integrationTestCacheConfig: integrationTestCacheConfig,
          platform: ExpressionOrValue.value(FlutterPlatform.ios.platform),
          baseTool: baseTool,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        ...InstallXcodeSigningBuilder(
          encodedProvisioningProfile: encodedProvisioningProfile,
          encodedSigningIdentity: encodedSigningIdentity,
          signingIdentityPassphrase: signingIdentityPassphrase,
        ).build(),
        Step.run(
          name: 'Build integration test app',
          run: "$baseTool build ios --release '$integrationTestPaths'",
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
        Step.run(
          name: 'Build test instrumentation app',
          run: 'xcodebuild build-for-testing '
              '-workspace Runner.xcworkspace '
              '-scheme Runner '
              '-configuration Release '
              '-sdk iphoneos '
              '-derivedDataPath ../build/ios_integration',
          workingDirectory: '$workingDirectory/$integrationTestProject/ios',
        ),
        Step.run(
          name: 'Create integration test package',
          run: 'zip -r --must-match app-release.zip '
              'Release-iphoneos *.xctestrun',
          workingDirectory:
              '$workingDirectory/$integrationTestProject/build/ios_integration/Build/Products',
        ),
        ...SetupGCloudBuilder(
          firebaseProjectId: firebaseProjectId,
          firebaseCredentials: firebaseCredentials,
        ).build(),
        Step.run(
          name: 'Run integration tests',
          run: 'gcloud firebase test ios run '
              '--type xctest '
              '--test build/ios_integration/Build/Products/app-release.zip',
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
      ];
}
