import '../../common/api/step_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class DockerImageBuilder implements StepBuilder {
  final Expression repository;
  final Expression dockerHubUsername;
  final Expression dockerHubToken;
  final Expression dockerPlatforms;
  final Expression dockerBuildArgs;

  DockerImageBuilder({
    required this.repository,
    required this.dockerHubUsername,
    required this.dockerHubToken,
    required this.dockerPlatforms,
    required this.dockerBuildArgs,
  });

  @override
  Iterable<Step> build() => [
        const Step.uses(
          name: 'Setup QEMU',
          uses: Tools.dockerSetupQemuAction,
        ),
        const Step.uses(
          name: 'Setup docker buildx',
          uses: Tools.dockerSetupBuildxAction,
        ),
        ...CheckoutBuilder(repository: repository).build(),
        Step.uses(
          name: 'Login to Docker Hub',
          uses: Tools.dockerLoginAction,
          withArgs: <String, dynamic>{
            'username': dockerHubUsername.toString(),
            'password': dockerHubToken.toString(),
          },
        ),
        Step.uses(
          name: 'Build and push image',
          uses: Tools.dockerBuildAndPushAction,
          withArgs: <String, dynamic>{
            'pull': true,
            'push': true,
            'sbom': true,
            'platforms':
                (dockerPlatforms & dockerPlatforms | const Expression('yeah'))
                    .toString(),
            'build-args': dockerBuildArgs.toString(),
            'tags': null,
          },
        ),
      ];
}
