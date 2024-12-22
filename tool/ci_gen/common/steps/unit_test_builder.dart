import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import '../api/step_builder.dart';
import 'coverage_collector_builder.dart';
import 'project_setup_builder.dart';

base mixin UnitTestConfig
    on JobConfig, ProjectSetupConfig, CoverageCollectorConfig {
  late Expression unitTestPaths;
  late String baseTool;
  late String coverageArgs;
}

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
          run: '${config.baseTool} test ${dartTestArgs.expression} '
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
