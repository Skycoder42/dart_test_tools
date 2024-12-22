import '../../common/jobs/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/dart_sdk_builder.dart';

base mixin DartSdkJobConfig on SdkJobConfig {
  late Expression dartSdkVersion;

  @override
  void expand() {
    baseTool = 'dart';
    runTool = '$baseTool run';
    super.expand();
  }
}

base mixin DartSdkJobBuilderMixin<TConfig extends DartSdkJobConfig>
    on SdkJobBuilder<TConfig> {
  @override
  Iterable<Step> buildSetupSdkSteps() => [
        ...DartSdkBuilder(dartSdkVersion: config.dartSdkVersion).build(),
      ];
}
