import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class CheckoutBuilder implements StepBuilder {
  final String? path;
  final Expression? repository;
  final Expression? gitRef;
  final ExpressionOrValue? persistCredentials;
  final int? fetchDepth;
  final Expression? withSubmodules;
  final Expression? token;

  const CheckoutBuilder({
    this.path,
    this.repository,
    this.gitRef,
    this.persistCredentials,
    this.fetchDepth,
    this.withSubmodules,
    this.token,
  });

  @override
  Iterable<Step> build() => [
    Step.uses(
      name: repository != null ? 'Checkout $repository' : 'Checkout repository',
      uses: Tools.actionsCheckout,
      withArgs: <String, dynamic>{
        'persist-credentials': persistCredentials?.asValue ?? false,
        if (path != null) 'path': path,
        if (repository != null) 'repository': repository.toString(),
        if (gitRef != null) 'ref': gitRef.toString(),
        if (fetchDepth != null) 'fetch-depth': fetchDepth,
        if (withSubmodules != null) 'submodules': withSubmodules.toString(),
        if (token != null) 'token': token.toString(),
      },
    ),
  ];
}
