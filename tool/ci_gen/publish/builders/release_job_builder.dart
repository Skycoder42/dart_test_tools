import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/job.dart';
import '../steps/release_builder.dart';

class ReleaseJobBuilder implements JobBuilder {
  final Expression releaseRef;
  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;

  ReleaseJobBuilder({
    required this.releaseRef,
    required this.repository,
    required this.workingDirectory,
    required this.tagPrefix,
  });

  @override
  String get name => 'release';

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Create release if needed',
        runsOn: 'ubuntu-latest',
        ifExpression: const Expression('github.ref').eq(releaseRef),
        needs: needs?.map((j) => j.name).toList(),
        outputs: {
          ReleaseBuilder.versionUpdate.name: ReleaseBuilder.versionUpdate,
        },
        steps: [
          ...ReleaseBuilder(
            repository: repository,
            workingDirectory: workingDirectory,
            tagPrefix: tagPrefix,
          ).build(),
        ],
      );
}
