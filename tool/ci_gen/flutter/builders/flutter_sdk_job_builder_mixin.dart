import '../../common/builders/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/flutter_sdk_builder.dart';

mixin FlutterSdkJobBuilderMixin on SdkJobBuilder {
  Expression get flutterSdkChannel;
  Expression get javaJdkVersion;

  @override
  String get baseTool => 'flutter';

  @override
  Iterable<Step> buildSetupSdkSteps([
    Expression? buildPlatform,
    Expression? enableDesktopCondition,
  ]) =>
      [
        ...FlutterSdkBuilder(
          flutterSdkChannel: flutterSdkChannel,
          javaJdkVersion: javaJdkVersion,
          buildPlatform: buildPlatform,
          enableDesktopCondition: enableDesktopCondition,
        ).build(),
      ];
}
