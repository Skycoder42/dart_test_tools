import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/expression_builder.dart';
import '../api/job_builder.dart';
import '../steps/coverage_builder_mixin.dart';
import '../steps/validate_coverage_builder.dart';

class ValidateCoverageJobBuilder implements JobBuilder {
  static const _supportedPlatforms = ['linux', 'windows', 'macos', 'web'];

  final Expression repository;
  final Expression workingDirectory;
  final Expression unitTestPaths;
  final Expression minCoverage;
  final Expression coverageExclude;
  final Expression platforms;

  ValidateCoverageJobBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.unitTestPaths,
    required this.minCoverage,
    required this.coverageExclude,
    required ExpressionBuilderFn<List<String>> platforms,
  }) : platforms = platforms(_supportedPlatforms);

  @override
  JobId get id => const JobId('coverage');

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Validate coverage',
        ifExpression: CoverageBuilderMixin.createRunCoverageExpression(
              minCoverage,
            ) &
            (unitTestPaths.ne(const Expression.literal(''))),
        needs: needs?.ids,
        runsOn: 'ubuntu-latest',
        steps: [
          ...ValidateCoverageBuilder(
            repository: repository,
            workingDirectory: workingDirectory,
            minCoverage: minCoverage,
            coverageExclude: coverageExclude,
            platforms: platforms,
            supportedPlatforms: _supportedPlatforms,
          ).build(),
        ],
      );
}
