import '../../common/api/expression_builder.dart';
import '../../common/builders/unit_test_job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import 'flutter_sdk_job_builder_mixin.dart';

class FlutterUnitTestJobBuilder extends UnitTestJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;

  FlutterUnitTestJobBuilder({
    required JobId analyzeJobId,
    required this.flutterSdkChannel,
    required Expression repository,
    required Expression workingDirectory,
    required Expression buildRunner,
    required Expression unitTestPaths,
    required Expression minCoverage,
    required ExpressionBuilderFn<List<String>> platforms,
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
  String get coverageArgs => '--coverage';

  @override
  bool get needsFormatting => false;
}
