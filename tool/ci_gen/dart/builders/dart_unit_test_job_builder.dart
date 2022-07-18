import '../../common/builders/unit_test_job_builder.dart';
import '../../types/expression.dart';
import 'dart_sdk_job_builder_mixin.dart';

class DartUnitTestJobBuilder extends UnitTestJobBuilder
    with DartSdkJobBuilderMixin {
  @override
  final Expression dartSdkVersion;

  DartUnitTestJobBuilder({
    required super.analyzeJobId,
    required super.repository,
    required super.workingDirectory,
    required super.buildRunner,
    required super.unitTestPaths,
    required super.minCoverage,
    required super.platforms,
    required this.dartSdkVersion,
  });

  @override
  String get coverageArgs => '--coverage=coverage';

  @override
  bool get needsFormatting => true;
}
