import '../../common/inputs.dart';
import '../../common/jobs/analyze_job_builder.dart';
import '../../types/step.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterAnalyzeJobConfig extends AnalyzeJobConfig
    with FlutterSdkJobConfig {
  @override
  late final javaJdkVersion = inputContext(WorkflowInputs.javaJdkVersion);

  FlutterAnalyzeJobConfig(super.inputContext, super.secretContext);
}

final class FlutterAnalyzeJobBuilder
    extends AnalyzeJobBuilder<FlutterAnalyzeJobConfig>
    with FlutterSdkJobBuilderMixin<FlutterAnalyzeJobConfig> {
  const FlutterAnalyzeJobBuilder({required super.config});

  @override
  Iterable<Step> buildAnalyzeSteps() => [
    Step.run(
      name: 'Static analysis',
      run: 'flutter analyze',
      workingDirectory: config.workingDirectory.toString(),
    ),
  ];
}
