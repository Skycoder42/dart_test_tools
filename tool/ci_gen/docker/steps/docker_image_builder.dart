import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin DockerImageConfig on JobConfig {
  late final imageName = inputContext(WorkflowInputs.imageName);
  late final version = inputContext(WorkflowInputs.version);
  late final extraTags = inputContext(WorkflowInputs.extraTags);
  late final dockerPlatforms = inputContext(WorkflowInputs.dockerPlatforms);
  late final dockerBuildArgs = inputContext(WorkflowInputs.dockerBuildArgs);
  late final dockerHubUsername =
      secretContext(WorkflowSecrets.dockerHubUsername);
  late final dockerHubToken = secretContext(WorkflowSecrets.dockerHubToken);
}

class DockerImageBuilder implements StepBuilder {
  static const _setupBuildxId = StepId('setup-docker-buildx');
  static final _buildxPlatformsOutput = _setupBuildxId.output('platforms');

  static const _generateTags = StepId('generate-tags');
  static final _generateTagsOutput = _generateTags.output('tags');

  final DockerImageConfig config;

  DockerImageBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        const Step.uses(
          name: 'Setup QEMU',
          uses: Tools.dockerSetupQemuAction,
        ),
        const Step.uses(
          id: _setupBuildxId,
          name: 'Setup docker buildx',
          uses: Tools.dockerSetupBuildxAction,
        ),
        Step.run(
          id: _generateTags,
          name: 'Generate docker image tags',
          run: '''
set -eo pipefail

major_version=\$(cut -d. -f1 <<< '${config.version}')
minor_version=\$(cut -d. -f1-2 <<< '${config.version}')
patch_version=\$(cut -d. -f1-3 <<< '${config.version}')

image_versions+=( latest "v\${major_version}" "v\${minor_version}" "v\${patch_version}" )
if [ '${config.version}' != "\$patch_version"  ]; then
  image_versions+=( 'v${config.version}' )
fi

image_versions+=( ${config.extraTags} )

${_generateTagsOutput.bashSetterMultiLine('''printf '${config.imageName}:%s\\n' "\${image_versions[@]}"''', isCommand: true)}
''',
        ),
        Step.uses(
          name: 'Login to Docker Hub',
          uses: Tools.dockerLoginAction,
          withArgs: <String, dynamic>{
            'username': config.dockerHubUsername.toString(),
            'password': config.dockerHubToken.toString(),
          },
        ),
        Step.uses(
          name: 'Build and push image',
          uses: Tools.dockerBuildAndPushAction,
          withArgs: <String, dynamic>{
            'platforms': (config.dockerPlatforms.ne(Expression.empty) &
                        config.dockerPlatforms |
                    _buildxPlatformsOutput.expression)
                .toString(),
            'build-args': config.dockerBuildArgs.toString(),
            'tags': _generateTagsOutput.expression.toString(),
            'pull': true,
            'sbom': true,
            'provenance': true,
            'push': true,
          },
        ),
      ];
}
