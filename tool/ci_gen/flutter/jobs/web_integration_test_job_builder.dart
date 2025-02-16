import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../flutter_platform.dart';
import '../steps/web_integration_test_builder.dart';
import 'common_integration_test_config.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class WebIntegrationTestJobConfig extends CommonIntegrationTestJobConfig
    with WebIntegrationTestConfig {
  WebIntegrationTestJobConfig(super.inputContext, super.secretContext);
}

final class WebIntegrationTestJobBuilder
    extends SdkJobBuilder<WebIntegrationTestJobConfig>
    with FlutterSdkJobBuilderMixin<WebIntegrationTestJobConfig> {
  final JobIdOutput enabledPlatformsOutput;

  WebIntegrationTestJobBuilder({
    required this.enabledPlatformsOutput,
    required super.config,
  });

  @override
  JobId get id => const JobId('integration_tests_web');

  @override
  Job build() => Job(
    name: 'Integration tests (web)',
    ifExpression:
        config.integrationTestPaths.ne(Expression.empty) &
        EnabledPlatforms.check(
          enabledPlatformsOutput.expression,
          Expression.literal(FlutterPlatform.web.platform),
        ),
    needs: {enabledPlatformsOutput.jobId},
    runsOn: FlutterPlatform.web.os.id,
    steps: [
      ...buildSetupSdkSteps(
        buildPlatform: ExpressionOrValue.value(FlutterPlatform.web.platform),
      ),
      ...WebIntegrationTestBuilder(config: config).build(),
    ],
  );
}
