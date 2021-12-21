import '../../common/builders/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'dart_sdk_job_builder_mixin.dart';

class DartAnalyzeJobBuilder extends AnalyzeJobBuilder
    with DartSdkJobBuilderMixin {
  @override
  final Expression dartSdkVersion;

  DartAnalyzeJobBuilder({
    required Expression repository,
    required Expression workingDirectory,
    required Expression buildRunner,
    required Expression analyzeImage,
    required Expression publishExclude,
    required this.dartSdkVersion,
  }) : super(
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          analyzeImage: analyzeImage,
          publishExclude: publishExclude,
        );

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'dart analyze --fatal-infos',
          workingDirectory: workingDirectory.toString(),
        )
      ];
}
