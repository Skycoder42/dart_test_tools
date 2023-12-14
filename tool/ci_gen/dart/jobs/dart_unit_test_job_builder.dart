import '../../common/jobs/unit_test_job_builder.dart';
import '../../types/expression.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartUnitTestJobBuilder extends UnitTestJobBuilder
    with DartSdkJobBuilderMixin {
  @override
  final Expression dartSdkVersion;

  DartUnitTestJobBuilder({
    required super.analyzeJobId,
    required super.workingDirectory,
    required super.artifactDependencies,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.removePubspecOverrides,
    required super.unitTestPaths,
    required super.minCoverage,
    required this.dartSdkVersion,
  });

  @override
  String get coverageArgs => '--coverage=coverage';

  @override
  bool get needsFormatting => true;
}
