import '../../common/builders/sdk_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

mixin DartSdkJobBuilderMixin on SdkJobBuilder {
  Expression get dartSdkVersion;

  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';

  @override
  Iterable<Step> buildSetupSdkSteps([Expression? ifExpression]) => [
        Step.uses(
          name: 'Install Dart-SDK '
              '($dartSdkVersion)',
          ifExpression: ifExpression,
          uses: 'dart-lang/setup-dart@v1.3',
          withArgs: {
            'sdk': dartSdkVersion.toString(),
          },
        )
      ];
}
