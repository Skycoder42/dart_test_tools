import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import 'coverage_collector_builder.dart';
import 'platforms_builder_mixin.dart';
import 'project_setup_builder.dart';

abstract interface class IUnitTextMatrix implements ICoverageCollectorMatrix {
  Expression get dartTestArgs;
}

class UnitTestBuilder with PlatformsBuilderMixin implements StepBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression unitTestPaths;
  final Expression minCoverage;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final IUnitTextMatrix matrix;
  final String coverageArgs;
  final bool needsFormatting;

  const UnitTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.unitTestPaths,
    required this.minCoverage,
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
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          pubTool: pubTool,
          runTool: runTool,
          withPlatform: matrix.platform,
        ).build(),
        Step.run(
          name: 'Run unit tests',
          ifExpression: shouldRunExpression,
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
          ifExpression: shouldRunExpression,
        ).build(),
      ];
}
