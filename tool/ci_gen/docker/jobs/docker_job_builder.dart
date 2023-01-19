import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/docker_image_builder.dart';

class DockerJobBuilder implements JobBuilder {
  static const jobId = JobId('docker');

  final Expression dockerHubUsername;
  final Expression dockerHubToken;
  final Expression dockerImageName;
  final Expression dockerImageTags;
  final Expression dockerPlatforms;
  final Expression dockerBuildArgs;

  DockerJobBuilder({
    required this.dockerHubUsername,
    required this.dockerHubToken,
    required this.dockerImageName,
    required this.dockerImageTags,
    required this.dockerPlatforms,
    required this.dockerBuildArgs,
  });

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Build and publish Docker images',
        runsOn: 'ubuntu-latest',
        steps: [
          ...DockerImageBuilder(
            dockerHubUsername: dockerHubUsername,
            dockerHubToken: dockerHubToken,
            dockerImageName: dockerImageName,
            dockerImageTags: dockerImageTags,
            dockerPlatforms: dockerPlatforms,
            dockerBuildArgs: dockerBuildArgs,
          ).build(),
        ],
      );
}
