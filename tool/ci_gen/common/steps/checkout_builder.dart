import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../contexts.dart';
import '../tools.dart';

class CheckoutBuilder implements StepBuilder {
  final String? path;
  final Expression? repository;
  final Expression? gitRef;
  final ExpressionOrValue? persistCredentials;
  final int? fetchDepth;
  final Expression? token;
  final Expression? artifactDependencies;
  final Expression artifactTargetDir;

  const CheckoutBuilder({
    this.path,
    this.repository,
    this.gitRef,
    this.persistCredentials,
    this.fetchDepth,
    this.token,
    this.artifactDependencies,
    this.artifactTargetDir = Runner.temp,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: repository != null
              ? 'Checkout $repository'
              : 'Checkout repository',
          uses: Tools.actionsCheckout,
          withArgs: <String, dynamic>{
            'persist-credentials': persistCredentials?.asValue ?? false,
            if (path != null) 'path': path,
            if (repository != null) 'repository': repository.toString(),
            if (gitRef != null) 'ref': gitRef.toString(),
            if (fetchDepth != null) 'fetch-depth': fetchDepth,
            if (token != null) 'token': token.toString(),
          },
        ),
        if (artifactDependencies != null)
          Step.uses(
            name: 'Download artifacts',
            ifExpression: artifactDependencies!.ne(Expression.empty),
            uses: Tools.actionsDownloadArtifact,
            withArgs: {
              'pattern': 'package-*',
              'path': '$artifactTargetDir/.artifacts',
            },
          ),
      ];
}
