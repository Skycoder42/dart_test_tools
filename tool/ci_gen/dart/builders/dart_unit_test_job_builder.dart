import '../../common/api/expression_builder.dart';
import '../../common/builders/unit_test_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import 'dart_sdk_job_builder_mixin.dart';

class DartUnitTestJobBuilder extends UnitTestJobBuilder
    with DartSdkJobBuilderMixin {
  @override
  final Expression dartSdkVersion;

  DartUnitTestJobBuilder({
    required JobId analyzeJobId,
    required Expression repository,
    required Expression workingDirectory,
    required Expression buildRunner,
    required Expression unitTestPaths,
    required Expression minCoverage,
    required ExpressionBuilderFn<List<String>> platforms,
    required this.dartSdkVersion,
  }) : super(
          analyzeJobId: analyzeJobId,
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          unitTestPaths: unitTestPaths,
          minCoverage: minCoverage,
          platforms: platforms,
        );

  @override
  String get coverageArgs => '--coverage=coverage';

  @override
  bool get needsFormatting => true;
}
