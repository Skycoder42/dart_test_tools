import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/step.dart';
import '../api/workflow_input.dart';

mixin ProjectSetupBuilderMixin {
  @protected
  final repositoryInput = const WorkflowInput(
    name: 'repository',
    input: Input(
      type: Type.string,
      required: false,
      description: 'The repository to check out. Passed as "repository" to '
          '"actions/checkout".',
    ),
  );

  @protected
  final workingDirectoryInput = const WorkflowInput(
    name: 'workingDirectory',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: '.',
      description: 'The root directory of the dart package to build and test.',
    ),
  );

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
        Step.uses(
          name: 'Checkout repository ${Expression.input(repositoryInput)}',
          uses: 'actions/checkout@v2',
          withArgs: {
            'repository': Expression.input(repositoryInput),
          },
        ),
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
