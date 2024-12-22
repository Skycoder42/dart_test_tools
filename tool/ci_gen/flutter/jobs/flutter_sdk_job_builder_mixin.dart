import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/flutter_sdk_builder.dart';

base mixin FlutterSdkJobConfig on SdkJobConfig {
  late Expression flutterSdkChannel;
  Expression? javaJdkVersion;

  @override
  void expand() {
    baseTool = 'flutter';
    isFlutter = const ExpressionOrValue.value(true);
    super.expand();
  }
}

base mixin FlutterSdkJobBuilderMixin<TConfig extends FlutterSdkJobConfig>
    on SdkJobBuilder<TConfig> {
  @override
  Iterable<Step> buildSetupSdkSteps({
    ExpressionOrValue? buildPlatform,
  }) =>
      [
        ...FlutterSdkBuilder(
          flutterSdkChannel: config.flutterSdkChannel,
          javaJdkVersion: config.javaJdkVersion,
          buildPlatform: buildPlatform,
        ).build(),
      ];
}
