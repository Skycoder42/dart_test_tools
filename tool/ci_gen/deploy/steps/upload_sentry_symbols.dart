import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/secrets.dart';
import '../../types/env.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

base mixin UploadSentrySymbolsConfig
    on JobConfig, WorkingDirectoryConfig, SdkJobConfig {
  late final sentryAuthToken = secretContext(WorkflowSecrets.sentryAuthToken);
  // late final sentryDist = secretContext(WorkflowSecrets.sentryDist);
}

class UploadSentrySymbolsBuilder implements StepBuilder {
  final UploadSentrySymbolsConfig config;

  const UploadSentrySymbolsBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install sentry_dart_plugin',
          ifExpression: config.sentryAuthToken.ne(Expression.empty),
          run: '${config.pubTool} global activate sentry_dart_plugin',
        ),
        Step.run(
          name: 'Upload debug symbols',
          ifExpression: config.sentryAuthToken.ne(Expression.empty),
          run: '${config.pubTool} global run sentry_dart_plugin',
          env: Env({
            'SENTRY_AUTH_TOKEN': config.sentryAuthToken.toString(),
            // 'SENTRY_DIST': config.sentryDist.toString(),
          }),
          workingDirectory: config.workingDirectory.toString(),
        ),
      ];
}
