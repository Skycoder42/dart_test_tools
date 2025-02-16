import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/flutter_sdk_builder.dart';

base mixin FlutterSdkJobConfig on SdkJobConfig {
  late final flutterSdkChannel = inputContext(WorkflowInputs.flutterSdkChannel);
  Expression? get javaJdkVersion => null;

  @override
  ExpressionOrValue get isFlutter => const ExpressionOrValue.value(true);

  @override
  String get baseTool => 'flutter';
}

base mixin FlutterSdkJobBuilderMixin<TConfig extends FlutterSdkJobConfig>
    on SdkJobBuilder<TConfig> {
  @override
  Iterable<Step> buildSetupSdkSteps({ExpressionOrValue? buildPlatform}) => [
    ...FlutterSdkBuilder(
      flutterSdkChannel: config.flutterSdkChannel,
      javaJdkVersion: config.javaJdkVersion,
      buildPlatform: buildPlatform,
    ).build(),
  ];
}
