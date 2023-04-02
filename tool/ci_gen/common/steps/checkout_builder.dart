import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class CheckoutBuilder implements StepBuilder {
  final Expression? gitRef;
  final String? path;
  final Expression? persistCredentials;

  const CheckoutBuilder({
    this.gitRef,
    this.path,
    this.persistCredentials,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Checkout repository',
          uses: Tools.actionsCheckout,
          withArgs: <String, dynamic>{
            'persist-credentials': persistCredentials?.toString() ?? false,
            if (path != null) 'path': path,
            if (gitRef != null) 'ref': gitRef.toString(),
          },
        ),
      ];
}
