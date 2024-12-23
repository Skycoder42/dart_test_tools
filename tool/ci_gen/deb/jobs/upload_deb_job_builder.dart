import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/environments.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/packagecloud_upload_builder.dart';

final class UploadDebJobConfig extends JobConfig with PackagecloudUploadConfig {
  UploadDebJobConfig(super.inputContext, super.secretContext);
}

class UploadDebJobBuilder implements JobBuilder {
  final JobId packageJobId;
  final UploadDebJobConfig config;

  const UploadDebJobBuilder({
    required this.packageJobId,
    required this.config,
  });

  @override
  JobId get id => const JobId('upload_deb');

  @override
  Job build() => Job(
        name: 'Upload deb package to packagecloud',
        runsOn: 'ubuntu-latest',
        needs: {
          packageJobId,
        },
        environment: Environments.packagecloud,
        steps: [
          ...PackagecloudUploadBuilder(config: config).build(),
        ],
      );
}
