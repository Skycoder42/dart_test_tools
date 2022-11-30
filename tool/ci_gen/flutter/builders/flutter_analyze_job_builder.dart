import '../../common/builders/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'flutter_sdk_job_builder_mixin.dart';

class FlutterAnalyzeJobBuilder extends AnalyzeJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;

  const FlutterAnalyzeJobBuilder({
    required this.flutterSdkChannel,
    required super.repository,
    required super.workingDirectory,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.analyzeImage,
    required super.publishExclude,
    required super.extendedAnalyzerArgs,
  });

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'flutter analyze',
          workingDirectory: workingDirectory.toString(),
        )
      ];
}
