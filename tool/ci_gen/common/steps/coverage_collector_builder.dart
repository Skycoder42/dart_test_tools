import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';
import 'coverage_builder_mixin.dart';

abstract class ICoverageCollectorMatrix {
  Expression get platform;
  Expression get lcovCleanCommand;
}

class CoverageCollectorBuilder
    with CoverageBuilderMixin
    implements StepBuilder {
  final Expression workingDirectory;
  @override
  final Expression minCoverage;
  final bool needsFormatting;
  final String runTool;
  final ICoverageCollectorMatrix matrix;
  final Expression? ifExpression;

  const CoverageCollectorBuilder({
    required this.workingDirectory,
    required this.minCoverage,
    required this.needsFormatting,
    required this.runTool,
    required this.matrix,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        if (needsFormatting)
          Step.run(
            name: 'Convert coverage data to lcov format',
            ifExpression: _coverageExpression,
            run: '$runTool coverage:format_coverage --lcov --check-ignore '
                '--in=coverage --out=coverage/lcov.info '
                '--report-on=lib',
            workingDirectory: workingDirectory.toString(),
          ),
        Step.run(
          name: 'Normalize coverage paths',
          ifExpression: _coverageExpression,
          run: matrix.lcovCleanCommand.toString(),
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Upload coverage data',
          ifExpression: _coverageExpression,
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'coverage-info-${matrix.platform}',
            'path': '$workingDirectory/coverage/lcov.info',
            'retention-days': 1,
            'if-no-files-found': 'error',
          },
        ),
      ];

  Expression get _coverageExpression => runCoverageExpression & ifExpression;
}
