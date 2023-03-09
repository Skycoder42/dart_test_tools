import '../../common/builders/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'dart_sdk_job_builder_mixin.dart';

class DartAnalyzeJobBuilder extends AnalyzeJobBuilder
    with DartSdkJobBuilderMixin {
  @override
  final Expression dartSdkVersion;

  const DartAnalyzeJobBuilder({
    required super.workingDirectory,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.analyzeImage,
    required super.extendedAnalyzerArgs,
    required super.panaScoreThreshold,
    required this.dartSdkVersion,
  });

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'dart analyze --fatal-infos',
          workingDirectory: workingDirectory.toString(),
        )
      ];
}
