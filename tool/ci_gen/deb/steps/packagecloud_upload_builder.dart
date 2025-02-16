import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/secrets.dart';
import '../../common/tools.dart';
import '../../types/step.dart';

base mixin PackagecloudUploadConfig on JobConfig {
  late final repository = inputContext(WorkflowInputs.packagecloudRepository);
  late final packagecloudToken = secretContext(
    WorkflowSecrets.packagecloudToken,
  );
}

class PackagecloudUploadBuilder implements StepBuilder {
  final PackagecloudUploadConfig config;

  const PackagecloudUploadBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    const Step.uses(
      name: 'Download debian package',
      uses: Tools.actionsDownloadArtifact,
      withArgs: {'name': 'debian-package', 'path': 'deb'},
    ),
    Step.uses(
      name: 'Upload debian package to packagecloud',
      uses: Tools.lpenzGhactionPackagecloud,
      withArgs: {'repository': config.repository.toString()},
      env: {'PACKAGECLOUD_TOKEN': config.packagecloudToken.toString()},
    ),
  ];
}
