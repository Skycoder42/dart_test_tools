import '../../common/builders/unit_test_job_builder.dart';
import 'dart_sdk_job_builder_mixin.dart';

class DartUnitTestJobBuilder extends UnitTestJobBuilder
    with DartSdkJobBuilderMixin {
  const DartUnitTestJobBuilder();

  @override
  String get coverageArgs => '--coverage=coverage';

  @override
  bool get needsFormatting => true;
}
