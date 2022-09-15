import '../../common/builders/unit_test_job_builder.dart';
import '../../types/expression.dart';
import 'flutter_sdk_job_builder_mixin.dart';

class FlutterUnitTestJobBuilder extends UnitTestJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;

  FlutterUnitTestJobBuilder({
    required super.analyzeJobId,
    required this.flutterSdkChannel,
    required super.repository,
    required super.workingDirectory,
    required super.buildRunner,
    required super.unitTestPaths,
    required super.minCoverage,
    required super.platforms,
  });

  @override
  String get coverageArgs => '--coverage';

  @override
  bool get needsFormatting => false;
}
