import '../../common/jobs/unit_test_job_builder.dart';
import '../dart_platform.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartUnitTestJobConfig extends UnitTestJobConfig
    with DartSdkJobConfig {
  @override
  String get coverageArgs => '--coverage=coverage';

  @override
  bool get needsFormatting => true;

  DartUnitTestJobConfig(super.inputContext, super.secretContext);
}

final class DartUnitTestJobBuilder
    extends UnitTestJobBuilder<DartUnitTestJobConfig>
    with DartSdkJobBuilderMixin<DartUnitTestJobConfig> {
  DartUnitTestJobBuilder({
    required super.enabledPlatformsOutput,
    required super.config,
  }) : super(platformSelectors: DartPlatform.values);
}
