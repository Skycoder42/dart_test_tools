import '../../common/builders/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'flutter_sdk_job_builder_mixin.dart';

class FlutterAnalyzeJobBuilder extends AnalyzeJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;

  const FlutterAnalyzeJobBuilder({
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required super.repository,
    required super.workingDirectory,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.analyzeImage,
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
