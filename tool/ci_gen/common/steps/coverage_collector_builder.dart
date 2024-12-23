import '../../types/runs_on.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../jobs/sdk_job_builder.dart';
import '../tools.dart';
import 'coverage_builder_mixin.dart';

base mixin CoverageCollectorConfig
    on JobConfig, SdkJobConfig, WorkingDirectoryConfig, CoverageBuilderConfig {
  bool get needsFormatting;
}

final class LcovCleanCommandMatrixProperty
    extends IMatrixProperty<IPlatformMatrixSelector> {
  const LcovCleanCommandMatrixProperty();

  @override
  String get name => 'lcovCleanCommand';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
        IPlatformMatrixSelector(os: RunsOn.ubuntuLatest) =>
          r'sed -i "s#SF:$PWD/#SF:#g" coverage/lcov.info',
        IPlatformMatrixSelector(os: RunsOn.macosLatest) ||
        IPlatformMatrixSelector(os: RunsOn.macos13) =>
          r'sed -i "" "s#SF:$PWD/#SF:#g" coverage/lcov.info',
        IPlatformMatrixSelector(os: RunsOn.windowsLatest) =>
          r'(Get-Content coverage\lcov.info).replace("SF:$PWD\", "SF:").replace("\", "/") | Set-Content coverage\lcov.info',
      };
}

class CoverageCollectorBuilder implements StepBuilder {
  final CoverageCollectorConfig config;
  final PlatformMatrixProperty platform;
  final LcovCleanCommandMatrixProperty lcovCleanCommand;

  const CoverageCollectorBuilder({
    required this.config,
    required this.lcovCleanCommand,
    required this.platform,
  });

  @override
  Iterable<Step> build() => [
        if (config.needsFormatting)
          Step.run(
            name: 'Convert coverage data to lcov format',
            ifExpression: config.runCoverageExpression,
            run: '${config.runTool} coverage:format_coverage '
                '--lcov '
                '--check-ignore '
                '--in=coverage '
                '--out=coverage/lcov.info '
                '--report-on=lib',
            workingDirectory: config.workingDirectory.toString(),
          ),
        Step.run(
          name: 'Normalize coverage paths',
          ifExpression: config.runCoverageExpression,
          run: lcovCleanCommand.expression.toString(),
          workingDirectory: config.workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Upload coverage data',
          ifExpression: config.runCoverageExpression,
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'coverage-info-${platform.expression}',
            'path': '${config.workingDirectory}/coverage/lcov.info',
            'retention-days': 1,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
