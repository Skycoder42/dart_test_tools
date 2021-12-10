import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/api/workflow_input.dart';
import '../../common/builder_mixins/project_setup_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/step.dart';

mixin DartSdkInstallMixin on ProjectSetupBuilderMixin {
  @protected
  final dartSdkVersionInput = const WorkflowInput(
    name: 'dartSdkVersion',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'stable',
      description: 'The Dart-SDK version. '
          'Passed as "sdk" to "dart-lang/setup-dart"',
    ),
  );

  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';

  @override
  @protected
  Iterable<WorkflowInput> get setupInputs => [
        ...super.setupInputs,
        dartSdkVersionInput,
      ];

  @override
  Step createInstallSdkStep() => Step.uses(
        name: 'Install Dart-SDK '
            '(${Expression.input(dartSdkVersionInput)})',
        uses: 'dart-lang/setup-dart@v1.3',
        withArgs: {
          'sdk': Expression.input(dartSdkVersionInput),
        },
      );
}
