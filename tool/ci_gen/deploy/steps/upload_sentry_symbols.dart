import '../../common/api/step_builder.dart';
import '../../types/env.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class UploadSentrySymbolsBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression sentryAuthToken;
  final Expression sentryDist;
  final String pubTool;

  const UploadSentrySymbolsBuilder({
    required this.workingDirectory,
    required this.sentryAuthToken,
    required this.sentryDist,
    required this.pubTool,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install sentry_dart_plugin',
          ifExpression: sentryAuthToken.ne(Expression.empty),
          run: '$pubTool global activate sentry_dart_plugin',
        ),
        Step.run(
          name: 'Upload debug symbols',
          ifExpression: sentryAuthToken.ne(Expression.empty),
          run: '$pubTool global run sentry_dart_plugin',
          env: Env({
            'SENTRY_AUTH_TOKEN': sentryAuthToken.toString(),
            'SENTRY_DIST': sentryDist.toString(),
          }),
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
