import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../api/job_config.dart';
import '../api/working_directory_config.dart';
import '../inputs.dart';
import '../steps/coverage_builder_mixin.dart';
import '../steps/validate_coverage_builder.dart';

final class ValidateCoverageJobConfig extends JobConfig
    with WorkingDirectoryConfig, CoverageBuilderConfig, ValidateCoverageConfig {
  late final unitTestPaths = inputContext(WorkflowInputs.unitTestPaths);

  ValidateCoverageJobConfig(super.inputContext, super.secretContext);
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
