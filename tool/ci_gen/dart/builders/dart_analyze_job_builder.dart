import '../../common/builders/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../builder_mixins/dart_sdk_install_mixin.dart';

class DartAnalyzeJobBuilder extends AnalyzeJobBuilder with DartSdkInstallMixin {
  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';

  @override
  Step createAnalyzeStep() => Step.run(
        name: 'Static analysis',
        run: '$baseTool analyze --fatal-infos',
        workingDirectory: Expression.input(workingDirectoryInput),
      );
}
