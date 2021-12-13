import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../api/workflow_input.dart';

class CheckoutBuilder implements StepBuilder {
  final WorkflowInput repository;

  const CheckoutBuilder({
    required this.repository,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Checkout repository ${Expression.input(repository)}',
          uses: 'actions/checkout@v2',
          withArgs: {
            'repository': Expression.input(repository),
          },
        ),
      ];
}
