import '../../common/builders/unit_test_job_builder.dart';
import '../builder_mixins/dart_sdk_install_mixin.dart';

class DartUnitTestJobBuilder extends UnitTestJobBuilder
    with DartSdkInstallMixin {
  @override
  String get runCoverageArgs => '--coverage=coverage';

  @override
  bool get needsFormatting => true;
}
