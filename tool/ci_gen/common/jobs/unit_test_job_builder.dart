import 'package:meta/meta.dart';

import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import '../steps/coverage_collector_builder.dart';
import '../steps/unit_test_builder.dart';
import 'sdk_job_builder.dart';

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

abstract base class UnitTestJobBuilder extends SdkJobBuilder
    with
        MatrixJobBuilderMixin<UnitTestMatrix, IPlatformMatrixSelector>,
        PlatformJobBuilderMixin<UnitTestMatrix> {
  final JobIdOutput enabledPlatformsOutput;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression unitTestPaths;
  final Expression minCoverage;

  @override
  final UnitTestMatrix matrix;

  UnitTestJobBuilder({
    required List<IPlatformMatrixSelector> platformSelectors,
    required this.enabledPlatformsOutput,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.unitTestPaths,
    required this.minCoverage,
  }) : matrix = UnitTestMatrix(platformSelectors);

  @override
  JobId get id => const JobId('unit_tests');

  @override
  Expression get enabledPlatforms => enabledPlatformsOutput.expression;

  @protected
  String get coverageArgs;

  @protected
  bool get needsFormatting;

  @override
  Job buildGeneric(String runsOn) => Job(
        name: 'Unit tests',
        ifExpression: unitTestPaths.ne(Expression.empty),
        needs: {
          enabledPlatformsOutput.jobId,
        },
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
            isFlutter: isFlutter,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            coverageArgs: coverageArgs,
            needsFormatting: needsFormatting,
          ).build(),
        ],
      );
}
