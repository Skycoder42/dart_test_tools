import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class CheckoutBuilder implements StepBuilder {
  final Expression? repository;
  final Expression? ifExpression;
  final Expression? gitRef;
  final String? path;

  const CheckoutBuilder({
    this.repository,
    this.ifExpression,
    this.gitRef,
    this.path,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Checkout repository ${repository ?? ''}',
          ifExpression: ifExpression,
          uses: Tools.actionsCheckout,
          withArgs: <String, dynamic>{
            if (repository != null) 'repository': repository.toString(),
            if (path != null) 'path': path,
            if (gitRef != null) 'ref': gitRef.toString(),
          },
        ),
      ];
}
