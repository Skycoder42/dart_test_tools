import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../inputs.dart';
import '../tools.dart';
import 'checkout_builder.dart';
import 'coverage_builder_mixin.dart';

base mixin ValidateCoverageConfig
    on JobConfig, WorkingDirectoryConfig, CoverageBuilderConfig {
  late final coverageExclude = inputContext(WorkflowInputs.coverageExclude);
}

class ValidateCoverageBuilder implements StepBuilder {
  final ValidateCoverageConfig config;

  const ValidateCoverageBuilder({
    required this.config,
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
        ...const CheckoutBuilder().build(),
        Step.uses(
          name: 'Download coverage data',
          uses: Tools.actionsDownloadArtifact,
          withArgs: <String, dynamic>{
            'path': '${config.workingDirectory}/coverage',
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
          workingDirectory: config.workingDirectory.toString(),
        ),
        Step.run(
          name: 'Remove excluded files from coverage data',
          run: 'lcov --ignore-errors unused '
              '--remove coverage/combined.info '
              '--output-file coverage/cleaned.info '
              '${config.coverageExclude}',
          workingDirectory: config.workingDirectory.toString(),
        ),
        Step.run(
          name: 'Generate coverage report',
          run: 'genhtml --no-function-coverage --synthesize-missing '
              '-o coverage/html coverage/cleaned.info',
          workingDirectory: config.workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Upload coverage HTML report',
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'coverage-html',
            'path': '${config.workingDirectory}/coverage/html',
            'retention-days': 14,
            'if-no-files-found': 'error',
          },
        ),
        Step.uses(
          name: 'Validate coverage is at least ${config.minCoverage}%',
          uses: Tools.veryGoodOpenSourceVeryGoodCoverage,
          withArgs: <String, dynamic>{
            'path': '${config.workingDirectory}/coverage/cleaned.info',
            'min_coverage': config.minCoverage.toString(),
          },
        ),
      ];
}
