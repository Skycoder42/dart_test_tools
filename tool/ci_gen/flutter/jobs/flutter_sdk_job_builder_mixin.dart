import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/flutter_sdk_builder.dart';

base mixin FlutterSdkJobBuilderMixin on SdkJobBuilder {
  Expression get flutterSdkChannel;

  Expression? get javaJdkVersion => null;

  @override
  String get baseTool => 'flutter';

  @override
  Iterable<Step> buildSetupSdkSteps({
    ExpressionOrValue? buildPlatform,
  }) =>
      [
        ...FlutterSdkBuilder(
          flutterSdkChannel: flutterSdkChannel,
          javaJdkVersion: javaJdkVersion,
          buildPlatform: buildPlatform,
        ).build(),
      ];
}
