import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/environments.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/docker_image_builder.dart';

final class DockerJobConfig extends JobConfig with DockerImageConfig {
  DockerJobConfig({
    required Expression imageName,
    required Expression version,
    required Expression extraTags,
    required Expression dockerPlatforms,
    required Expression dockerBuildArgs,
    required Expression dockerHubUsername,
    required Expression dockerHubToken,
  }) {
    this.imageName = imageName;
    this.version = version;
    this.extraTags = extraTags;
    this.dockerPlatforms = dockerPlatforms;
    this.dockerBuildArgs = dockerBuildArgs;
    this.dockerHubUsername = dockerHubUsername;
    this.dockerHubToken = dockerHubToken;
    expand();
  }
}

class DockerJobBuilder implements JobBuilder {
  static const jobId = JobId('docker');

  final DockerJobConfig config;

  DockerJobBuilder({
    required this.config,
  });

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Build and publish Docker images',
        runsOn: 'ubuntu-latest',
        environment: Environments.dockerHub,
        steps: [
          ...DockerImageBuilder(config: config).build(),
        ],
      );
}
