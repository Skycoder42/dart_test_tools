import '../../common/inputs.dart';
import '../../common/jobs/analyze_job_builder.dart';
import '../../types/step.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterAnalyzeJobConfig(super.inputContext, super.secretContext)
    extends AnalyzeJobConfig
    with FlutterSdkJobConfig {
  @override
  late final javaJdkVersion = inputContext(WorkflowInputs.javaJdkVersion);
}

final class const FlutterAnalyzeJobBuilder({required super.config})
    extends AnalyzeJobBuilder<FlutterAnalyzeJobConfig>
    with FlutterSdkJobBuilderMixin<FlutterAnalyzeJobConfig> {
  @override
  Iterable<Step> buildAnalyzeSteps() => [
    Step.run(
      name: 'Static analysis',
      run: 'flutter analyze',
      workingDirectory: config.workingDirectory.toString(),
    ),
  ];
}
