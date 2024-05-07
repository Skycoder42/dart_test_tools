import '../../types/expression.dart';
import '../../types/runs_on.dart';
import '../../types/step.dart';
import '../api/matrix_job_builder_mixin.dart';
import '../api/platform_matrix_job_builder_mixin.dart';
import '../api/step_builder.dart';
import '../tools.dart';
import 'coverage_builder_mixin.dart';

final class LcovCleanCommandMatrixProperty
    extends IMatrixProperty<IPlatformMatrixSelector> {
  const LcovCleanCommandMatrixProperty();

  @override
  String get name => 'lcovCleanCommand';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
        IPlatformMatrixSelector(os: RunsOn.ubuntuLatest) =>
          r'sed -i "s#SF:$PWD/#SF:#g" coverage/lcov.info',
        IPlatformMatrixSelector(os: RunsOn.macosLatestArm64) ||
        IPlatformMatrixSelector(os: RunsOn.macosLatestX86) =>
          r'sed -i "" "s#SF:$PWD/#SF:#g" coverage/lcov.info',
        IPlatformMatrixSelector(os: RunsOn.windowsLatest) =>
          r'(Get-Content coverage\lcov.info).replace("SF:$PWD\", "SF:").replace("\", "/") | Set-Content coverage\lcov.info',
      };
}

class CoverageCollectorBuilder
    with CoverageBuilderMixin
    implements StepBuilder {
  final Expression workingDirectory;
  @override
  final Expression minCoverage;
  final PlatformMatrixProperty platform;
  final LcovCleanCommandMatrixProperty lcovCleanCommand;
  final bool needsFormatting;
  final String runTool;

  const CoverageCollectorBuilder({
    required this.workingDirectory,
    required this.minCoverage,
    required this.lcovCleanCommand,
    required this.needsFormatting,
    required this.platform,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        if (needsFormatting)
          Step.run(
            name: 'Convert coverage data to lcov format',
            ifExpression: runCoverageExpression,
            run: '$runTool coverage:format_coverage --lcov --check-ignore '
                '--in=coverage --out=coverage/lcov.info '
                '--report-on=lib',
            workingDirectory: workingDirectory.toString(),
          ),
        Step.run(
          name: 'Normalize coverage paths',
          ifExpression: runCoverageExpression,
          run: lcovCleanCommand.expression.toString(),
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Upload coverage data',
          ifExpression: runCoverageExpression,
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'coverage-info-${platform.expression}',
            'path': '$workingDirectory/coverage/lcov.info',
            'retention-days': 1,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
