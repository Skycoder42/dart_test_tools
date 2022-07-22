import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

class ReleaseJobBuilder implements JobBuilder {
  static const jobId = JobId('release');
  static final updateOutput = jobId.output('update');

  final JobId compileJobId;
  final Expression releaseRef;
  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;

  const ReleaseJobBuilder({
    required this.compileJobId,
    required this.releaseRef,
    required this.repository,
    required this.workingDirectory,
    required this.tagPrefix,
  });

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Create release if needed',
        needs: {compileJobId},
        ifExpression: const Expression('github.ref').eq(releaseRef),
        outputs: {
          updateOutput: ReleaseBuilder.versionUpdate,
        },
        runsOn: 'ubuntu-latest',
        steps: [
          ...ReleaseBuilder(
            repository: repository,
            workingDirectory: workingDirectory,
            tagPrefix: tagPrefix,
          ).build(),
        ],
      );
}
