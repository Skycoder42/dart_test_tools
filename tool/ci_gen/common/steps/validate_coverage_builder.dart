import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';
import 'checkout_builder.dart';
import 'coverage_builder_mixin.dart';
import 'platforms_builder_mixin.dart';

class ValidateCoverageBuilder
    with CoverageBuilderMixin, PlatformsBuilderMixin
    implements StepBuilder {
  final Expression workingDirectory;
  @override
  final Expression minCoverage;
  final Expression coverageExclude;
  @override
  final Expression platforms;
  final List<String> supportedPlatforms;

  const ValidateCoverageBuilder({
    required this.workingDirectory,
    required this.minCoverage,
    required this.coverageExclude,
    required this.platforms,
    required this.supportedPlatforms,
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
        for (final platform in supportedPlatforms)
          _createCoverageDownloadStep(platform),
        Step.run(
          name: 'Merge coverage data',
          run: r'''
set -e
LCOV_ARGS=""
for dir in $(ls coverage); do
  dos2unix coverage/$dir/lcov.info
  LCOV_ARGS="$LCOV_ARGS --add-tracefile coverage/$dir/lcov.info"
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

  Step _createCoverageDownloadStep(String platform) => Step.uses(
        name: 'Download $platform coverage data',
        ifExpression: shouldRunExpression(Expression.literal(platform)),
        uses: Tools.actionsDownloadArtifact,
        withArgs: <String, dynamic>{
          'name': 'coverage-info-$platform',
          'path': '$workingDirectory/coverage/$platform',
        },
      );
}
