import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

class ReleaseJobBuilder implements JobBuilder {
  @override
  JobId get id => const JobId('release');

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
  Job build() => Job(
        name: 'Create release if needed',
        needs: {compileJobId},
        ifExpression: const Expression('github.ref').eq(releaseRef),
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
