import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import 'coverage_collector_builder.dart';
import 'project_setup_builder.dart';

final class DartTestArgsMatrixProperty
    extends IMatrixProperty<IPlatformMatrixSelector> {
  const DartTestArgsMatrixProperty();

  @override
  String get name => 'dartTestArgs';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
        IPlatformMatrixSelector(isWeb: true) => '-p chrome',
        _ => null,
      };
}

class UnitTestBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression unitTestPaths;
  final Expression minCoverage;
  final PlatformMatrixProperty platform;
  final DartTestArgsMatrixProperty dartTestArgs;
  final LcovCleanCommandMatrixProperty lcovCleanCommand;
  final String baseTool;
  final String pubTool;
  final String runTool;
  final String coverageArgs;
  final bool needsFormatting;

  const UnitTestBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.unitTestPaths,
    required this.minCoverage,
    required this.baseTool,
    required this.pubTool,
    required this.runTool,
    required this.dartTestArgs,
    required this.lcovCleanCommand,
    required this.platform,
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
          removePubspecOverrides: removePubspecOverrides,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Run unit tests',
          run: '$baseTool test ${dartTestArgs.expression} '
              '$coverageArgs --reporter github $unitTestPaths',
          workingDirectory: workingDirectory.toString(),
        ),
        ...CoverageCollectorBuilder(
          workingDirectory: workingDirectory,
          minCoverage: minCoverage,
          runTool: runTool,
          platform: platform,
          lcovCleanCommand: lcovCleanCommand,
          needsFormatting: needsFormatting,
        ).build(),
      ];
}
