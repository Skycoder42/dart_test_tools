import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../contexts.dart';
import '../tools.dart';

class CheckoutBuilder implements StepBuilder {
  final Expression? gitRef;
  final String? path;
  final ExpressionOrValue? persistCredentials;
  final int? fetchDepth;
  final Expression? artifactDependencies;
  final Expression artifactTargetDir;

  const CheckoutBuilder({
    this.gitRef,
    this.path,
    this.persistCredentials,
    this.fetchDepth,
    this.artifactDependencies,
    this.artifactTargetDir = Runner.temp,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Checkout repository',
          uses: Tools.actionsCheckout,
          withArgs: <String, dynamic>{
            'persist-credentials': persistCredentials?.asParameter ?? false,
            if (path != null) 'path': path,
            if (gitRef != null) 'ref': gitRef.toString(),
            if (fetchDepth != null) 'fetch-depth': fetchDepth,
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
