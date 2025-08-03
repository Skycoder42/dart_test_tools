import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import '../api/step_builder.dart';
import '../inputs.dart';
import 'coverage_collector_builder.dart';
import 'project_setup_builder.dart';

base mixin UnitTestConfig
    on JobConfig, ProjectSetupConfig, CoverageCollectorConfig {
  late final unitTestPaths = inputContext(WorkflowInputs.unitTestPaths);
  String get coverageArgs;

  @override
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);

  @override
  late final artifactDependencies = inputContext(
    WorkflowInputs.artifactDependencies,
  );
}

final class DartTestArgsMatrixProperty
    extends IMatrixProperty<IPlatformMatrixSelector> {
  const DartTestArgsMatrixProperty();

  @override
  String get name => 'dartTestArgs';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
    IPlatformMatrixSelector(isWeb: true) => '--platform chrome',
    _ => null,
  };
}

class UnitTestBuilder implements StepBuilder {
  final UnitTestConfig config;
  final PlatformMatrixProperty platform;
  final DartTestArgsMatrixProperty dartTestArgs;
  final LcovCleanCommandMatrixProperty lcovCleanCommand;

  const UnitTestBuilder({
    required this.config,
    required this.platform,
    required this.dartTestArgs,
    required this.lcovCleanCommand,
  });

  @override
  Iterable<Step> build() => [
    ...ProjectSetupBuilder(config: config).build(),
    Step.run(
      name: 'Run unit tests',
      run:
          '${config.baseTool} test ${dartTestArgs.expression} '
          '${config.coverageArgs} '
          '--reporter github ${config.unitTestPaths} || [ \$? = 79 ]',
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    ...CoverageCollectorBuilder(
      config: config,
      platform: platform,
      lcovCleanCommand: lcovCleanCommand,
    ).build(),
  ];
}
