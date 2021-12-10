import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/step.dart';
import '../api/workflow_input.dart';
import 'checkout_builder_mixin.dart';

mixin ProjectSetupBuilderMixin on CheckoutBuilderMixin {
  @protected
  final buildRunnerInput = const WorkflowInput(
    name: 'buildRunner',
    input: Input(
      type: Type.boolean,
      required: false,
      defaultValue: false,
      description: 'Specify whether build_runner is used in the project '
          '(defaults to false).',
    ),
  );

  @protected
  String get baseTool;
  @protected
  String get pubTool => '$baseTool pub';
  @protected
  String get runTool => '$pubTool run';

  @protected
  Step createInstallSdkStep();

  @protected
  Iterable<WorkflowInput> get setupInputs => [
        repositoryInput,
        workingDirectoryInput,
        buildRunnerInput,
      ];

  @protected
  Iterable<Step> createSetupSteps() => [
        createInstallSdkStep(),
        const Step.run(
          name: 'Install yq (Windows)',
          ifExpression: "runner.os == 'Windows'",
          run: 'choco install yq',
        ),
        const Step.run(
          name: 'Install yq (macOS)',
          ifExpression: "runner.os == 'macOS'",
          run: 'brew install yq',
        ),
        ...createCheckoutSteps(),
        Step.run(
          name: 'Remove dependency overrides',
          run: 'yq e -i "del(.dependency_overrides)" pubspec.yaml',
          workingDirectory: Expression.input(workingDirectoryInput),
        ),
        Step.run(
          name: 'Restore dart packages',
          run: '$pubTool get',
          workingDirectory: Expression.input(workingDirectoryInput),
        ),
        Step.run(
          name: 'Create build files',
          ifExpression: buildRunnerInput.expression,
          run: '$runTool build_runner build',
          workingDirectory: Expression.input(workingDirectoryInput),
        ),
      ];
}
