import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class CheckoutBuilder implements StepBuilder {
  final Expression repository;
  final Expression? ifExpression;
  final String? path;

  const CheckoutBuilder({
    required this.repository,
    this.ifExpression,
    this.path,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Checkout repository $repository',
          ifExpression: ifExpression,
          uses: 'actions/checkout@v2',
          withArgs: <String, dynamic>{
            'repository': repository.toString(),
            if (path != null) 'path': path,
          },
        ),
      ];
}
