import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class CheckoutBuilder implements StepBuilder {
  final Expression repository;
  final Expression? ifExpression;

  const CheckoutBuilder({
    required this.repository,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Checkout repository $repository',
          ifExpression: ifExpression,
          uses: 'actions/checkout@v2',
          withArgs: {
            'repository': repository.toString(),
          },
        ),
      ];
}
