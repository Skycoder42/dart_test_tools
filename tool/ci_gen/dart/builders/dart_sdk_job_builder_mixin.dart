import '../../common/builders/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/dart_sdk_builder.dart';

mixin DartSdkJobBuilderMixin on SdkJobBuilder {
  Expression get dartSdkVersion;

  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';

  @override
  Iterable<Step> buildSetupSdkSteps([Expression? ifExpression]) => [
        ...DartSdkBuilder(
          dartSdkVersion: dartSdkVersion,
          ifExpression: ifExpression,
        ).build(),
      ];
}
