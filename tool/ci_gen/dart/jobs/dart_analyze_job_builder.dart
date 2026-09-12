import '../../common/inputs.dart';
import '../../common/jobs/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'dart_sdk_job_builder_mixin.dart';

final class DartAnalyzeJobConfig(super.inputContext, super.secretContext)
    extends AnalyzeJobConfig
    with DartSdkJobConfig {
  @override
  // ignore: overridden_fields to replace default value
  late final needsFlutterSdk = ExpressionOrValue.expression(
    inputContext(WorkflowInputs.needsFlutterSdk),
  );
}

final class const DartAnalyzeJobBuilder({required super.config})
    extends AnalyzeJobBuilder<DartAnalyzeJobConfig>
    with DartSdkJobBuilderMixin<DartAnalyzeJobConfig> {
  @override
  Iterable<Step> buildAnalyzeSteps() => [
    Step.run(
      name: 'Static analysis',
      run: 'dart analyze --fatal-infos',
      workingDirectory: config.workingDirectory.toString(),
    ),
  ];
}
