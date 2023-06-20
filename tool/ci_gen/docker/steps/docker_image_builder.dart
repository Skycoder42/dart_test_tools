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

  final Expression imageName;
  final Expression version;
  final Expression extraTags;
  final Expression dockerPlatforms;
  final Expression dockerBuildArgs;
  final Expression dockerHubUsername;
  final Expression dockerHubToken;

  DockerImageBuilder({
    required this.imageName,
    required this.version,
    required this.extraTags,
    required this.dockerPlatforms,
    required this.dockerBuildArgs,
    required this.dockerHubUsername,
    required this.dockerHubToken,
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

major_version=\$(cut -d. -f1 <<< '$version')
minor_version=\$(cut -d. -f1-2 <<< '$version')
patch_version=\$(cut -d. -f1-3 <<< '$version')

image_versions+=( latest "v\${major_version}" "v\${minor_version}" "v\${patch_version}" )
if [ '$version' != "\$patch_version"  ]; then
  image_versions+=( 'v$version' )
fi

image_versions+=( $extraTags )

${generateTagsOutput.bashSetterMultiLine('''printf '$imageName:%s\\n' "\${image_versions[@]}"''', isCommand: true)}
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
