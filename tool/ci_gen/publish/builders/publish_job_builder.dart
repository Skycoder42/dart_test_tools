import '../../common/api/job_builder.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../flutter/steps/flutter_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/publish_builder.dart';

class PublishJobBuilder implements JobBuilder {
  final Expression flutter;
  final Expression dartSdkVersion;
  final Expression flutterSdkChannel;
  final Expression javaJdkVersion;
  final Expression repository;
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
    required this.repository,
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
          ...PublishBuilder(
            flutter: flutter,
            repository: repository,
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            prePublish: prePublish,
            extraArtifacts: extraArtifacts,
          ).build(),
        ],
      );
}
