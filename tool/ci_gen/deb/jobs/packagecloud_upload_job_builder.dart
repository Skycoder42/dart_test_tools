import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/packagecloud_upload_builder.dart';

class PackagecloudUploadJobBuilder implements JobBuilder {
  final JobId packageJobId;
  final Expression repository;
  final Expression packagecloudToken;

  const PackagecloudUploadJobBuilder({
    required this.packageJobId,
    required this.repository,
    required this.packagecloudToken,
  });

  @override
  JobId get id => const JobId('packagecloud_upload');

  @override
  Job build() => Job(
        name: 'Upload deb package to packagecloud',
        runsOn: 'ubuntu-latest',
        needs: {
          packageJobId,
        },
        steps: [
          ...PackagecloudUploadBuilder(
            repository: repository,
            packagecloudToken: packagecloudToken,
          ).build(),
        ],
      );
}
