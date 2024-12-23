import '../../common/inputs.dart';
import '../../common/jobs/unit_test_job_builder.dart';
import '../../dart/dart_platform.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterUnitTestJobConfig extends UnitTestJobConfig
    with FlutterSdkJobConfig {
  @override
  late final javaJdkVersion = inputContext(WorkflowInputs.javaJdkVersion);

  @override
  String get coverageArgs => '--coverage';

  @override
  bool get needsFormatting => false;

  FlutterUnitTestJobConfig(super.inputContext, super.secretContext);
}

final class FlutterUnitTestJobBuilder
    extends UnitTestJobBuilder<FlutterUnitTestJobConfig>
    with FlutterSdkJobBuilderMixin<FlutterUnitTestJobConfig> {
  FlutterUnitTestJobBuilder({
    required super.enabledPlatformsOutput,
    required super.config,
  }) : super(platformSelectors: DartPlatform.values);
}
