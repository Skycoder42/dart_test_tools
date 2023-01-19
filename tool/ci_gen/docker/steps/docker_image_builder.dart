import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class DockerImageBuilder implements StepBuilder {
  static const setupBuildxId = StepId('setup-docker-buildx');
  static final buildxPlatformsOutput = setupBuildxId.output('platforms');

  static const generateTags = StepId('generate-tags');
  static final generateTagsOutput = generateTags.output('tags');

  final Expression dockerHubUsername;
  final Expression dockerHubToken;
  final Expression dockerImageName;
  final Expression dockerImageTags;
  final Expression dockerPlatforms;
  final Expression dockerBuildArgs;

  DockerImageBuilder({
    required this.dockerHubUsername,
    required this.dockerHubToken,
    required this.dockerImageName,
    required this.dockerImageTags,
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
          id: setupBuildxId,
          name: 'Setup docker buildx',
          uses: Tools.dockerSetupBuildxAction,
        ),
        Step.run(
          id: generateTags,
          name: 'Generate docker image tags',
          run: '''
set -eo pipefail

fullTagList=\$(echo '$dockerImageTags' | awk -vimage='$dockerImageName' '{print image "/" \$0}')
${generateTagsOutput.bashSetterMultiLine(r'$fullTagList')}
''',
        ),
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
            'platforms':
                (dockerPlatforms.ne(Expression.empty) & dockerPlatforms |
                        buildxPlatformsOutput.expression)
                    .toString(),
            'build-args': dockerBuildArgs.toString(),
            'tags': generateTagsOutput.expression.toString(),
            'pull': true,
            'sbom': true,
            'provenance': true,
            'push': true,
          },
        ),
      ];
}
