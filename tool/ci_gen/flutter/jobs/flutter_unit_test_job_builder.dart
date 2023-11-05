import '../../common/jobs/unit_test_job_builder.dart';
import '../../types/expression.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterUnitTestJobBuilder extends UnitTestJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;

  FlutterUnitTestJobBuilder({
    required super.analyzeJobId,
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required super.workingDirectory,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.unitTestPaths,
    required super.minCoverage,
  });

  @override
  String get coverageArgs => '--coverage';

  @override
  bool get needsFormatting => false;
}
