import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'coverage_collector_builder.dart';
import 'platforms_builder_mixin.dart';
import 'project_setup_builder.dart';

abstract class IUnitTextMatrix implements ICoverageCollectorMatrix {
  Expression get dartTestArgs;
}

class UnitTestBuilder with PlatformsBuilderMixin implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression releaseRef;
  final Expression buildRunner;
  final Expression unitTestPaths;
  final Expression minCoverage;
  @override
  final Expression platforms;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final IUnitTextMatrix matrix;
  final String coverageArgs;
  final bool needsFormatting;

  const UnitTestBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.releaseRef,
    required this.buildRunner,
    required this.unitTestPaths,
    required this.minCoverage,
    required this.platforms,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
    required this.matrix,
    required this.coverageArgs,
    required this.needsFormatting,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          releaseRef: releaseRef,
          buildRunner: buildRunner,
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: shouldRunExpression(matrix.platform),
        ).build(),
        Step.run(
          name: 'Run unit tests',
          ifExpression: shouldRunExpression(matrix.platform),
          run: '$baseTool test ${matrix.dartTestArgs} '
              '$coverageArgs --reporter github $unitTestPaths',
          workingDirectory: workingDirectory.toString(),
        ),
        ...CoverageCollectorBuilder(
          workingDirectory: workingDirectory,
          minCoverage: minCoverage,
          runTool: runTool,
          matrix: matrix,
          needsFormatting: needsFormatting,
          ifExpression: shouldRunExpression(matrix.platform),
        ).build(),
      ];
}
