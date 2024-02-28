import 'package:meta/meta.dart';

import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/coverage_collector_builder.dart';
import '../steps/unit_test_builder.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import 'sdk_job_builder.dart';

final class _UnitTestMatrix extends PlatformMatrix {
  const _UnitTestMatrix(super.selectors);

  DartTestArgsMatrixProperty get dartTestArgs => DartTestArgsMatrixProperty();

  LcovCleanCommandMatrixProperty get lcovCleanCommand =>
      LcovCleanCommandMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
        ...super.includeProperties,
        dartTestArgs,
        lcovCleanCommand,
      ];
}

abstract base class UnitTestJobBuilder extends SdkJobBuilder
    with
        MatrixJobBuilderMixin<_UnitTestMatrix, IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<_UnitTestMatrix> {
  final JobId analyzeJobId;
  @override
  final Expression enabledPlatforms;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression unitTestPaths;
  final Expression minCoverage;

  @override
  final _UnitTestMatrix matrix;

  UnitTestJobBuilder({
    required List<IPlatformMatrixSelector> platformSelectors,
    required this.analyzeJobId,
    required this.enabledPlatforms,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.unitTestPaths,
    required this.minCoverage,
  }) : matrix = _UnitTestMatrix(platformSelectors);

  @override
  JobId get id => const JobId('unit_tests');

  @protected
  String get coverageArgs;

  @protected
  bool get needsFormatting;

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Unit tests',
        ifExpression: unitTestPaths.ne(Expression.empty),
        needs: {analyzeJobId},
        runsOn: runsOn,
        steps: [
          ...buildSetupSdkSteps(),
          ...UnitTestBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            unitTestPaths: unitTestPaths,
            minCoverage: minCoverage,
            dartTestArgs: matrix.dartTestArgs,
            lcovCleanCommand: matrix.lcovCleanCommand,
            platform: matrix.platform,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            coverageArgs: coverageArgs,
            needsFormatting: needsFormatting,
          ).build(),
        ],
      );
}
