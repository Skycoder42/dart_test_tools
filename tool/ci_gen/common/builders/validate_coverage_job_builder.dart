import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../steps/coverage_builder_mixin.dart';
import '../steps/validate_coverage_builder.dart';

class ValidateCoverageJobBuilder implements JobBuilder {
  final JobId unitTestJobId;
  final Expression workingDirectory;
  final Expression unitTestPaths;
  final Expression minCoverage;
  final Expression coverageExclude;

  ValidateCoverageJobBuilder({
    required this.unitTestJobId,
    required this.workingDirectory,
    required this.unitTestPaths,
    required this.minCoverage,
    required this.coverageExclude,
  });

  @override
  JobId get id => const JobId('coverage');

  @override
  Job build() => Job(
        name: 'Validate coverage',
        ifExpression: CoverageBuilderMixin.createRunCoverageExpression(
              minCoverage,
            ) &
            (unitTestPaths.ne(Expression.empty)),
        needs: {unitTestJobId},
        runsOn: 'ubuntu-latest',
        steps: [
          ...ValidateCoverageBuilder(
            workingDirectory: workingDirectory,
            minCoverage: minCoverage,
            coverageExclude: coverageExclude,
          ).build(),
        ],
      );
}
