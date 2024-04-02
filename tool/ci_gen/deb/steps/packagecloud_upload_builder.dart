import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class PackagecloudUploadBuilder implements StepBuilder {
  final Expression repository;
  final Expression packagecloudToken;

  const PackagecloudUploadBuilder({
    required this.repository,
    required this.packagecloudToken,
  });

  @override
  Iterable<Step> build() => [
        const Step.uses(
          name: 'Download debian package',
          uses: Tools.actionsDownloadArtifact,
          withArgs: {
            'name': 'debian-package',
            'path': 'deb',
          },
        ),
        Step.uses(
          name: 'Upload debian package to packagecloud',
          uses: Tools.lpenzGhactionPackagecloud,
          withArgs: {
            'repository': repository.toString(),
          },
          env: {
            'PACKAGECLOUD_TOKEN': packagecloudToken.toString(),
          },
        ),
      ];
}
