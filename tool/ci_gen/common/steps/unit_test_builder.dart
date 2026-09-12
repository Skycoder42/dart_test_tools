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
}

final class const DartTestArgsMatrixProperty()
    extends IMatrixProperty<IPlatformMatrixSelector> {
  @override
  String get name => 'dartTestArgs';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
    IPlatformMatrixSelector(isWeb: true) => '--platform chrome',
    _ => null,
  };
}

class const UnitTestBuilder({
  required final UnitTestConfig config,
  required final PlatformMatrixProperty platform,
  required final DartTestArgsMatrixProperty dartTestArgs,
  required final LcovCleanCommandMatrixProperty lcovCleanCommand,
}) implements StepBuilder {
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
