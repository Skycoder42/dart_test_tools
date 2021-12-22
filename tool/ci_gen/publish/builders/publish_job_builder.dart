import '../../common/api/job_builder.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/publish_builder.dart';

class PublishJobBuilder implements JobBuilder {
  final Expression publish;
  final Expression releaseUpdate;
  final Expression flutter;
  final Expression dartSdkVersion;
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression publishExclude;
  final Expression pubDevCredentials;

  PublishJobBuilder({
    required this.publish,
    required this.releaseUpdate,
    required this.flutter,
    required this.dartSdkVersion,
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.publishExclude,
    required this.pubDevCredentials,
  });

  @override
  JobId get id => const JobId('publish');

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Publish to pub.dev',
        needs: needs?.ids,
        ifExpression:
            publish & releaseUpdate.eq(const Expression.literal('true')),
        runsOn: 'ubuntu-latest',
        steps: [
          ...DartSdkBuilder(
            dartSdkVersion: dartSdkVersion,
            ifExpression: flutter.not,
          ).build(),
          // TODO add flutter SDK
          ...PublishBuilder(
            flutter: flutter,
            repository: repository,
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            publishExclude: publishExclude,
            pubDevCredentials: pubDevCredentials,
          ).build(),
        ],
      );
}
