import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../api/job_config.dart';
import '../steps/coverage_builder_mixin.dart';
import '../steps/validate_coverage_builder.dart';

final class ValidateCoverageJobConfig extends JobConfig
    with CoverageBuilderConfig, ValidateCoverageConfig {
  final Expression unitTestPaths;

  ValidateCoverageJobConfig({
    required Expression workingDirectory,
    required this.unitTestPaths,
    required Expression minCoverage,
    required Expression coverageExclude,
  }) {
    this.workingDirectory = workingDirectory;
    this.minCoverage = minCoverage;
    this.coverageExclude = coverageExclude;
    expand();
  }
}

class ValidateCoverageJobBuilder implements JobBuilder {
  final JobId unitTestJobId;
  final ValidateCoverageJobConfig config;

  ValidateCoverageJobBuilder({
    required this.unitTestJobId,
    required this.config,
  });

  @override
  JobId get id => const JobId('coverage');

  @override
  Job build() => Job(
        name: 'Validate coverage',
        ifExpression: CoverageBuilderConfig.createRunCoverageExpression(
              config.minCoverage,
            ) &
            (config.unitTestPaths.ne(Expression.empty)),
        needs: {
          unitTestJobId,
        },
        runsOn: 'ubuntu-latest',
        steps: [
          ...ValidateCoverageBuilder(config: config).build(),
        ],
      );
}
