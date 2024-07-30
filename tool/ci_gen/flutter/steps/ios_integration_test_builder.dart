import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'prepare_integration_test_builder.dart';

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
  final Expression browserStackIosDevices;
  final Expression browserStackCredentials;
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
    required this.browserStackIosDevices,
    required this.browserStackCredentials,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        const Step.uses(
          name: 'Install hurl',
          uses: Tools.installHurl,
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
          platform: ExpressionOrValue.value(FlutterPlatform.ios.platform),
          baseTool: baseTool,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Build integration test app',
          run: '$baseTool build ios --release --no-codesign '
              "'$integrationTestPaths'",
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
        Step.run(
          name: 'Build test instrumentation app',
          run: 'xcodebuild '
              '-workspace Runner.xcworkspace '
              '-scheme Runner '
              '-config Flutter/Release.xcconfig '
              '-derivedDataPath ../build/ios_integration '
              '-sdk iphoneos '
              'build-for-testing',
          workingDirectory: '$workingDirectory/$integrationTestProject/ios',
        ),
        Step.run(
          name: 'Create integration test package',
          run: 'zip -r --must-match -- app-release.zip '
              'Release-iphoneos *.xctestrun',
          workingDirectory:
              '$workingDirectory/$integrationTestProject/build/ios_integration/Build/Products',
        ),
        Step.uses(
          name: 'Run integration tests',
          uses: Tools.hurl,
          withArgs: {
            'fileRoot': '$workingDirectory/$integrationTestProject',
            'user': browserStackCredentials.toString(),
            'script': '''
POST {{baseUrl}}/test-package
[MultipartFormData]
file: file,example/build/ios_integration/Build/Products/app-release.zip;
[Options]
variable: baseUrl=https://api-cloud.browserstack.com/app-automate/flutter-integration-tests/v2/ios
HTTP 200
[Captures]
testPackageUrl: jsonpath "\$['test_package_url']"

POST {{baseUrl}}/build
{
  "testPackage": "{{testPackageUrl}}",
  "project": "${Github.repository}",
  "buildTag": "${Github.sha}",
  "devices": $browserStackIosDevices,
  "deviceLogs": true
}
HTTP 200
[Captures]
buildId: jsonpath "\$['build_id']"
[Asserts]
jsonpath "\$.message" == "Success"

GET {{baseUrl}}/builds/{{buildId}}
[Options]
retry: 120
retry-interval: 30000
output: test-results.json
HTTP 200
[Asserts]
jsonpath "\$.status" not matches /(running|queued)/

GET {{baseUrl}}/builds/{{buildId}}
HTTP 200
[Asserts]
jsonpath "\$.status" matches /(passed|skipped)/
''',
          },
        ),
      ];
}
