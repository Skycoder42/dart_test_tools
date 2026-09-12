import '../../common/inputs.dart';
import '../../common/jobs/unit_test_job_builder.dart';
import '../../types/expression.dart';
import '../dart_platform.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartUnitTestJobConfig(super.inputContext, super.secretContext)
    extends UnitTestJobConfig
    with DartSdkJobConfig {
  @override
  String get coverageArgs => '--coverage=coverage';

  @override
  bool get needsFormatting => true;

  @override
  // ignore: overridden_fields to replace default value
  late final needsFlutterSdk = ExpressionOrValue.expression(
    inputContext(WorkflowInputs.needsFlutterSdk),
  );
}

final class DartUnitTestJobBuilder({
  required super.enabledPlatformsOutput,
  required super.config,
}) extends UnitTestJobBuilder<DartUnitTestJobConfig>
    with DartSdkJobBuilderMixin<DartUnitTestJobConfig> {
  this : super(platformSelectors: DartPlatform.values);
}
