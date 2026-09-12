import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/environments.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/docker_image_builder.dart';

final class DockerJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with DockerImageConfig;

class DockerJobBuilder({required final DockerJobConfig config})
    implements JobBuilder {
  static const jobId = JobId('docker');

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
    name: 'Build and publish Docker images',
    runsOn: 'ubuntu-latest',
    environment: Environments.dockerHub,
    steps: [...DockerImageBuilder(config: config).build()],
  );
}
