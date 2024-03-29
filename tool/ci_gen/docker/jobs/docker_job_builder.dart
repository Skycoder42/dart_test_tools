import '../../common/api/job_builder.dart';
import '../../common/environments.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/docker_image_builder.dart';

class DockerJobBuilder implements JobBuilder {
  static const jobId = JobId('docker');

  final Expression imageName;
  final Expression version;
  final Expression extraTags;
  final Expression dockerPlatforms;
  final Expression dockerBuildArgs;
  final Expression dockerHubUsername;
  final Expression dockerHubToken;

  DockerJobBuilder({
    required this.imageName,
    required this.version,
    required this.extraTags,
    required this.dockerPlatforms,
    required this.dockerBuildArgs,
    required this.dockerHubUsername,
    required this.dockerHubToken,
  });

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Build and publish Docker images',
        runsOn: 'ubuntu-latest',
        environment: Environments.dockerHub,
        steps: [
          ...DockerImageBuilder(
            imageName: imageName,
            version: version,
            extraTags: extraTags,
            dockerPlatforms: dockerPlatforms,
            dockerBuildArgs: dockerBuildArgs,
            dockerHubUsername: dockerHubUsername,
            dockerHubToken: dockerHubToken,
          ).build(),
        ],
      );
}
