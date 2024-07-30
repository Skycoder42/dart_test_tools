import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';
import 'prepare_integration_test_builder.dart';

class AndroidIntegrationTestBuilder implements StepBuilder {
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
  final Expression browserStackAndroidDevices;
  final Expression browserStackCredentials;
  final String baseTool;
  final String pubTool;
  final String runTool;

  const AndroidIntegrationTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required this.integrationTestCacheConfig,
    required this.browserStackAndroidDevices,
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
          platform: ExpressionOrValue.value(FlutterPlatform.android.platform),
          baseTool: baseTool,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Build integration test app',
          run: "$baseTool build apk --debug --target '$integrationTestPaths'",
          workingDirectory: '$workingDirectory/$integrationTestProject',
        ),
        Step.run(
          name: 'Build test instrumentation app',
          run: './gradlew app:assembleAndroidTest',
          workingDirectory: '$workingDirectory/$integrationTestProject/android',
        ),
        Step.uses(
          name: 'Run integration tests',
          uses: Tools.hurl,
          withArgs: {
            'verbose': true,
            'fileRoot': '$workingDirectory/$integrationTestProject',
            'user': browserStackCredentials.toString(),
            'script': '''
POST {{baseUrl}}/app
[MultipartFormData]
file: file,build/app/outputs/apk/debug/app-debug.apk;
[Options]
variable: baseUrl=https://api-cloud.browserstack.com/app-automate/flutter-integration-tests/v2/android
HTTP 200
[Captures]
appUrl: jsonpath "\$['app_url']"

POST {{baseUrl}}/test-suite
[MultipartFormData]
file: file,build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk;
HTTP 200
[Captures]
testSuiteUrl: jsonpath "\$['test_suite_url']"

POST {{baseUrl}}/build
{
  "app": "{{appUrl}}",
  "testSuite": "{{testSuiteUrl}}",
  "project": "${Github.repository}",
  "buildTag": "${Github.sha}",
  "devices": $browserStackAndroidDevices,
  "autoGrantPermissions": true
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
