import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../types/step.dart';
import '../steps/dart_sdk_builder.dart';

base mixin DartSdkJobConfig on SdkJobConfig {
  late final dartSdkVersion = inputContext(WorkflowInputs.dartSdkVersion);

  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';
}

base mixin DartSdkJobBuilderMixin<TConfig extends DartSdkJobConfig>
    on SdkJobBuilder<TConfig> {
  @override
  Iterable<Step> buildSetupSdkSteps() => [
    ...DartSdkBuilder(dartSdkVersion: config.dartSdkVersion).build(),
  ];
}
