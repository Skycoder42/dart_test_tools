import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/step.dart';
import '../api/workflow_input.dart';

mixin CheckoutBuilderMixin {
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
  Iterable<WorkflowInput> get checkoutInputs => [
        repositoryInput,
        workingDirectoryInput,
      ];

  @protected
  Iterable<Step> createCheckoutSteps() => [
        Step.uses(
          name: 'Checkout repository ${Expression.input(repositoryInput)}',
          uses: 'actions/checkout@v2',
          withArgs: {
            'repository': Expression.input(repositoryInput),
          },
        ),
      ];
}
