import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/contexts.dart';
import '../../common/environments.dart';
import '../../common/steps/project_prepare_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/run_publish_builder.dart';
import '../../common/steps/update_overrides_builder.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../flutter/steps/flutter_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/flutter_auth_builder.dart';
import '../steps/publish_builder.dart';

final class PublishJobConfig extends JobConfig
    with
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        RunPublishConfig,
        PublishConfig {
  final Expression dartSdkVersion;
  final Expression flutterSdkChannel;
  final Expression javaJdkVersion;
  final Expression tagPrefix;

  PublishJobConfig({
    required Expression flutter,
    required this.dartSdkVersion,
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required this.tagPrefix,
    required Expression workingDirectory,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression prePublish,
    required Expression extraArtifacts,
  }) {
    isFlutter = ExpressionOrValue.expression(flutter);
    this.workingDirectory = workingDirectory;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.prePublish = prePublish;
    this.extraArtifacts = extraArtifacts;
    localResolution = const ExpressionOrValue.value(false);
    expand();
  }
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
