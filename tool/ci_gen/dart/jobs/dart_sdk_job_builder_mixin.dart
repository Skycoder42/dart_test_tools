import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/dart_sdk_builder.dart';

base mixin DartSdkJobBuilderMixin on SdkJobBuilder {
  Expression get dartSdkVersion;

  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';

  @override
  Iterable<Step> buildSetupSdkSteps() => [
        ...DartSdkBuilder(dartSdkVersion: dartSdkVersion).build(),
      ];
}
