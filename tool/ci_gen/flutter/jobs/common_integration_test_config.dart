import '../../common/api/job_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../types/expression.dart';
import '../steps/prepare_integration_test_builder.dart';
import 'flutter_sdk_job_builder_mixin.dart';

base mixin CommonIntegrationTestConfig
    on JobConfig, PrepareIntegrationTestConfig {
  late Expression integrationTestPaths;
}

base class CommonIntegrationTestJobConfig extends JobConfig
    with
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        PrepareIntegrationTestConfig,
        CommonIntegrationTestConfig,
        SdkJobConfig,
        FlutterSdkJobConfig {
  CommonIntegrationTestJobConfig({
    required Expression flutterSdkChannel,
    Expression? javaJdkVersion,
    required Expression workingDirectory,
    required Expression artifactDependencies,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression removePubspecOverrides,
    required Expression localResolution,
    required Expression integrationTestSetup,
    required Expression integrationTestPaths,
    required Expression integrationTestProject,
    required Expression integrationTestCacheConfig,
  }) {
    this.flutterSdkChannel = flutterSdkChannel;
    this.javaJdkVersion = javaJdkVersion;
    this.workingDirectory = workingDirectory;
    this.artifactDependencies = artifactDependencies;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.removePubspecOverrides =
        ExpressionOrValue.expression(removePubspecOverrides);
    this.localResolution = ExpressionOrValue.expression(localResolution);
    this.integrationTestSetup = integrationTestSetup;
    this.integrationTestPaths = integrationTestPaths;
    this.integrationTestProject = integrationTestProject;
    this.integrationTestCacheConfig = integrationTestCacheConfig;
    expand();
  }
}
