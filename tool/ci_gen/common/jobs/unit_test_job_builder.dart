import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/job_config.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import '../steps/coverage_builder_mixin.dart';
import '../steps/coverage_collector_builder.dart';
import '../steps/project_prepare_builder.dart';
import '../steps/project_setup_builder.dart';
import '../steps/unit_test_builder.dart';
import '../steps/update_overrides_builder.dart';
import 'sdk_job_builder.dart';

base class UnitTestJobConfig extends JobConfig
    with
        UpdateOverridesConfig,
        ProjectPrepareConfig,
        ProjectSetupConfig,
        CoverageBuilderConfig,
        CoverageCollectorConfig,
        UnitTestConfig,
        SdkJobConfig {
  UnitTestJobConfig({
    required Expression workingDirectory,
    required Expression artifactDependencies,
    required Expression buildRunner,
    required Expression buildRunnerArgs,
    required Expression removePubspecOverrides,
    required Expression localResolution,
    required Expression unitTestPaths,
    required Expression minCoverage,
  }) {
    this.workingDirectory = workingDirectory;
    this.artifactDependencies = artifactDependencies;
    this.buildRunner = buildRunner;
    this.buildRunnerArgs = buildRunnerArgs;
    this.removePubspecOverrides =
        ExpressionOrValue.expression(removePubspecOverrides);
    this.localResolution = ExpressionOrValue.expression(localResolution);
    this.unitTestPaths = unitTestPaths;
    this.minCoverage = minCoverage;
    expand();
  }
}

final class UnitTestMatrix extends PlatformMatrix {
  const UnitTestMatrix(super._selectors);

  DartTestArgsMatrixProperty get dartTestArgs =>
      const DartTestArgsMatrixProperty();

  LcovCleanCommandMatrixProperty get lcovCleanCommand =>
      const LcovCleanCommandMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
        ...super.includeProperties,
        dartTestArgs,
        lcovCleanCommand,
      ];
}

abstract base class UnitTestJobBuilder<TConfig extends UnitTestJobConfig>
    extends SdkJobBuilder<TConfig>
    with
        MatrixJobBuilderMixin<UnitTestMatrix, IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<UnitTestMatrix> {
  final JobIdOutput enabledPlatformsOutput;
  @override
  final UnitTestMatrix matrix;

  UnitTestJobBuilder({
    required List<IPlatformMatrixSelector> platformSelectors,
    required this.enabledPlatformsOutput,
    required super.config,
  }) : matrix = UnitTestMatrix(platformSelectors);

  @override
  JobId get id => const JobId('unit_tests');

  @override
  Expression get enabledPlatforms => enabledPlatformsOutput.expression;

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Unit tests',
        ifExpression: config.unitTestPaths.ne(Expression.empty),
        needs: {
          enabledPlatformsOutput.jobId,
        },
        runsOn: runsOn,
        steps: [
          ...buildSetupSdkSteps(),
          ...UnitTestBuilder(
            config: config,
            dartTestArgs: matrix.dartTestArgs,
            lcovCleanCommand: matrix.lcovCleanCommand,
            platform: matrix.platform,
          ).build(),
        ],
      );
}
