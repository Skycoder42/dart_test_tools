import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

class ReleaseJobBuilder implements JobBuilder {
  static const jobId = JobId('release');

  final Expression releaseRef;
  final Expression dartSdkVersion;
  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;

  ReleaseJobBuilder({
    required this.releaseRef,
    required this.dartSdkVersion,
    required this.repository,
    required this.workingDirectory,
    required this.tagPrefix,
  });

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Create release if needed',
        runsOn: 'ubuntu-latest',
        ifExpression: const Expression('github.ref').eq(releaseRef),
        steps: [
          ...ReleaseBuilder(
            dartSdkVersion: dartSdkVersion,
            repository: repository,
            workingDirectory: workingDirectory,
            tagPrefix: tagPrefix,
          ).build(),
        ],
      );
}
