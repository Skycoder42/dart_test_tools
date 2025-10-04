import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../steps/prepare_integration_test_builder.dart';
import 'flutter_sdk_job_builder_mixin.dart';

base mixin CommonIntegrationTestConfig
    on JobConfig, PrepareIntegrationTestConfig {
  late final integrationTestPaths = inputContext(
    WorkflowInputs.integrationTestPaths,
  );

  @override
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);
}

base class CommonIntegrationTestJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        PrepareIntegrationTestConfig,
        CommonIntegrationTestConfig,
        FlutterSdkJobConfig {
  CommonIntegrationTestJobConfig(super.inputContext, super.secretContext);
}
