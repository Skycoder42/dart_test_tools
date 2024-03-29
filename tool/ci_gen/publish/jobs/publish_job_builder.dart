import '../../common/api/job_builder.dart';
import '../../common/environments.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../flutter/steps/flutter_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/flutter_auth_builder.dart';
import '../steps/publish_builder.dart';

class PublishJobBuilder implements JobBuilder {
  final Expression flutter;
  final Expression dartSdkVersion;
  final Expression flutterSdkChannel;
  final Expression javaJdkVersion;
  final Expression tagPrefix;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression prePublish;
  final Expression extraArtifacts;

  PublishJobBuilder({
    required this.flutter,
    required this.dartSdkVersion,
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required this.tagPrefix,
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.prePublish,
    required this.extraArtifacts,
  });

  @override
  JobId get id => const JobId('publish');

  @override
  Job build() => Job(
        name: 'Publish to pub.dev',
        environment: Environments.pubDeploy,
        ifExpression: const Expression('startsWith')([
          const Expression('github.ref'),
          const Expression('format')([
            const Expression.literal('refs/tags/{0}'),
            tagPrefix,
          ]),
        ]),
        permissions: const {
          'id-token': 'write',
        },
        runsOn: 'ubuntu-latest',
        steps: [
          ...DartSdkBuilder(
            dartSdkVersion: dartSdkVersion,
            ifExpression: flutter.not,
          ).build(),
          ...FlutterSdkBuilder(
            flutterSdkChannel: flutterSdkChannel,
            javaJdkVersion: javaJdkVersion,
            ifExpression: flutter,
          ).build(),
          ...FlutterAuthBuilder(
            ifExpression: flutter,
          ).build(),
          ...PublishBuilder(
            flutter: flutter,
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            prePublish: prePublish,
            extraArtifacts: extraArtifacts,
          ).build(),
        ],
      );
}
