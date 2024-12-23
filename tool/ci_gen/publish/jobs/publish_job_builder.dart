import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/environments.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/run_publish_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../flutter/steps/flutter_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/flutter_auth_builder.dart';
import '../steps/publish_builder.dart';

final class PublishJobConfig extends JobConfig
    with
        SdkJobConfig,
        WorkingDirectoryConfig,
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        RunPublishConfig,
        DartSdkJobConfig,
        FlutterSdkJobConfig,
        PublishConfig {
  late final tagPrefix = inputContext(WorkflowInputs.tagPrefix);

  PublishJobConfig(super.inputContext, super.secretContext);
}

class PublishJobBuilder implements JobBuilder {
  final PublishJobConfig config;

  PublishJobBuilder({
    required this.config,
  });

  @override
  JobId get id => const JobId('publish');

  @override
  Job build() => Job(
        name: 'Publish to pub.dev',
        environment: Environments.pubDeploy,
        ifExpression: const Expression('startsWith')([
          Github.ref,
          const Expression('format')([
            const Expression.literal('refs/tags/{0}'),
            config.tagPrefix,
          ]),
        ]),
        permissions: const {
          'id-token': 'write',
        },
        runsOn: 'ubuntu-latest',
        steps: [
          ...DartSdkBuilder(
            dartSdkVersion: config.dartSdkVersion,
            ifExpression: config.isFlutter.asExpression.not,
          ).build(),
          ...FlutterSdkBuilder(
            flutterSdkChannel: config.flutterSdkChannel,
            javaJdkVersion: config.javaJdkVersion,
            ifExpression: config.isFlutter.asExpression,
          ).build(),
          ...FlutterAuthBuilder(
            ifExpression: config.isFlutter.asExpression,
          ).build(),
          ...PublishBuilder(config: config).build(),
        ],
      );
}
