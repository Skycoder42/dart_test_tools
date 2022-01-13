import '../../common/builders/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/flutter_sdk_builder.dart';

mixin FlutterSdkJobBuilderMixin on SdkJobBuilder {
  Expression get flutterSdkChannel;

  @override
  String get baseTool => 'flutter';

  @override
  Iterable<Step> buildSetupSdkSteps([Expression? ifExpression]) => [
        ...FlutterSdkBuilder(
          flutterSdkChannel: flutterSdkChannel,
          ifExpression: ifExpression,
        ).build(),
      ];
}
