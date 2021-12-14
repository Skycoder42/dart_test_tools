// import 'package:freezed_annotation/freezed_annotation.dart';

// import '../../types/expression.dart';
// import '../../types/input.dart';
// import '../../types/job.dart';
// import '../../types/step.dart';
// import '../api/job_builder.dart';
// import '../api/workflow_input.dart';
// import '../builder_mixins/checkout_builder_mixin.dart';
// import '../builder_mixins/coverage_base_builder_mixin.dart';
// import '../builder_mixins/platforms_builder_mixin.dart';

// abstract class ValidateCoverageJobBuilder
//     with CheckoutBuilderMixin, CoverageBaseBuilderMixin, PlatformsBuilderMixin
//     implements JobBuilder {
//   @protected
//   final coverageExcludeInput = const WorkflowInput(
//     name: 'coverageExclude',
//     input: Input(
//       type: Type.string,
//       required: false,
//       description: 'Files to exclude from test coverage. Passed as '
//           'command line arguments to a bash script. Excludes should be '
//           'properly escaped, e.g. \'config.dart "**/*.g.dart"\'',
//     ),
//   );

//   @override
//   String get name => 'coverage';

//   @override
//   Iterable<WorkflowInput> get inputs => [
//         ...checkoutInputs,
//         ...coverageBaseInputs,
//         coverageExcludeInput,
//         ...platformsInputs,
//       ];

//   @override
//   Job build([Iterable<JobBuilder>? needs]) => Job(
//         name: 'Validate coverage',
//         ifExpression: '$runCoverageExpression && ', // TODO unit tests input
//         needs: needs?.map((jobBuilder) => jobBuilder.name).toList(),
//         runsOn: 'ubuntu-latest',
//         steps: [
//           const Step.run(
//             name: 'Install coverage tools',
//             run: 'sudo apt-get -qq install lcov dos2unix',
//           ),
//           ...createCheckoutSteps(),
//           for (final platform in supportedPlatforms)
//             _createCoverageDownloadStep(platform),
//           Step.run(
//             name: 'Merge coverage data',
//             run: r'''
// set -e
// LCOV_ARGS=""
// for dir in $(ls coverage); do
//   dos2unix coverage/$dir/lcov.info
//   LCOV_ARGS="$LCOV_ARGS --add-tracefile coverage/$dir/lcov.info"
// done
// lcov $LCOV_ARGS --output-file coverage/combined.info
// cat coverage/combined.info
// ''',
//             workingDirectory: Expression.input(workingDirectory),
//           ),
//           Step.run(
//             name: 'Remove excluded files from coverage data',
//             run: 'lcov --remove coverage/combined.info '
//                 '--output-file coverage/cleaned.info '
//                 '${Expression.input(coverageExcludeInput)}',
//             workingDirectory: Expression.input(workingDirectory),
//           ),
//           Step.run(
//             name: 'Generate coverage report',
//             run: 'genhtml --no-function-coverage '
//                 '-o coverage/html coverage/cleaned.info',
//             workingDirectory: Expression.input(workingDirectory),
//           ),
//           Step.uses(
//             name: 'Upload coverage HTML report',
//             uses: 'actions/upload-artifact@v2',
//             withArgs: {
//               'name': 'coverage-html',
//               'path': '${Expression.input(workingDirectory)}/coverage/html',
//             },
//           ),
//           Step.uses(
//             name: 'Validate coverage is at least '
//                 '${Expression.input(minCoverageInput)}%',
//             uses: 'VeryGoodOpenSource/very_good_coverage@v1.1.1',
//             withArgs: {
//               'path':
//                   '${Expression.input(workingDirectory)}/coverage/cleaned.info',
//               'min_coverage': Expression.input(minCoverageInput),
//             },
//           ),
//         ],
//       );

//   Step _createCoverageDownloadStep(String platform) => Step.uses(
//         name: 'Download $platform coverage data',
//         ifExpression: shouldRunExpression(Expression.literal(platform)),
//         uses: 'actions/download-artifact@v2',
//         withArgs: {
//           'name': 'coverage-info-$platform',
//           'path': '${Expression.input(workingDirectory)}/coverage/$platform',
//         },
//       );
// }
