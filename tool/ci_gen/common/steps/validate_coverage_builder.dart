import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';
import 'checkout_builder.dart';
import 'coverage_builder_mixin.dart';

class ValidateCoverageBuilder with CoverageBuilderMixin implements StepBuilder {
  final Expression workingDirectory;
  @override
  final Expression minCoverage;
  final Expression coverageExclude;

  const ValidateCoverageBuilder({
    required this.workingDirectory,
    required this.minCoverage,
    required this.coverageExclude,
  });

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Install coverage tools',
          run: '''
set -e
sudo apt-get -qq update
sudo apt-get -qq install lcov dos2unix
''',
        ),
        ...CheckoutBuilder().build(),
        Step.uses(
          name: 'Download coverage data',
          uses: Tools.actionsDownloadArtifact,
          withArgs: <String, dynamic>{
            'path': '$workingDirectory/coverage',
            'pattern': 'coverage-info-*',
          },
        ),
        Step.run(
          name: 'Merge coverage data',
          run: r'''
set -e
LCOV_ARGS=""
for dir in coverage/coverage-info-*; do
  dos2unix $dir/lcov.info
  LCOV_ARGS="$LCOV_ARGS --add-tracefile $dir/lcov.info"
done
lcov $LCOV_ARGS --output-file coverage/combined.info
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Remove excluded files from coverage data',
          run: 'lcov --remove coverage/combined.info '
              '--output-file coverage/cleaned.info '
              '$coverageExclude',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Generate coverage report',
          run: 'genhtml --no-function-coverage '
              '-o coverage/html coverage/cleaned.info',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Upload coverage HTML report',
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'coverage-html',
            'path': '$workingDirectory/coverage/html',
            'retention-days': 14,
            'if-no-files-found': 'error',
          },
        ),
        Step.uses(
          name: 'Validate coverage is at least $minCoverage%',
          uses: Tools.veryGoodOpenSourceVeryGoodCoverage,
          withArgs: <String, dynamic>{
            'path': '$workingDirectory/coverage/cleaned.info',
            'min_coverage': minCoverage.toString(),
          },
        ),
      ];
}
