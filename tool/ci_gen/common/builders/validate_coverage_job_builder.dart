import '../../types/expression.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../api/workflow_input.dart';
import '../inputs.dart';
import '../steps/coverage_builder_mixin.dart';
import '../steps/validate_coverage_builder.dart';

class ValidateCoverageJobBuilder implements JobBuilder {
  const ValidateCoverageJobBuilder();

  @override
  String get name => 'coverage';

  @override
  Iterable<WorkflowInput> get inputs => [
        WorkflowInputs.repository,
        WorkflowInputs.workingDirectory,
        WorkflowInputs.minCoverage,
        WorkflowInputs.coverageExclude,
        _platforms,
      ];

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Validate coverage',
        ifExpression: CoverageBuilderMixin.createRunCoverageExpression(
              WorkflowInputs.minCoverage.expression,
            ) &
            (WorkflowInputs.unitTestPaths.expression
                .ne(const Expression.literal(''))),
        needs: needs?.map((jobBuilder) => jobBuilder.name).toList(),
        runsOn: 'ubuntu-latest',
        steps: [
          ...ValidateCoverageBuilder(
            repository: WorkflowInputs.repository.expression,
            workingDirectory: WorkflowInputs.workingDirectory.expression,
            minCoverage: WorkflowInputs.minCoverage.expression,
            coverageExclude: WorkflowInputs.coverageExclude.expression,
            platforms: _platforms.expression,
            supportedPlatforms: _supportedPlatforms,
          ).build(),
        ],
      );

  static const _supportedPlatforms = ['linux', 'windows', 'macos', 'web'];

  WorkflowInput get _platforms => WorkflowInputs.platforms(_supportedPlatforms);
}
