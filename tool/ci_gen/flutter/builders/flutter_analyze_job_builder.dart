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
    required Expression repository,
    required Expression workingDirectory,
    required Expression buildRunner,
    required Expression analyzeImage,
    required Expression publishExclude,
    required Expression extendedAnalyzerArgs,
  }) : super(
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          analyzeImage: analyzeImage,
          publishExclude: publishExclude,
          extendedAnalyzerArgs: extendedAnalyzerArgs,
        );

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'flutter analyze',
          workingDirectory: workingDirectory.toString(),
        )
      ];
}
