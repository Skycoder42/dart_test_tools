import '../../../common/api/job_config.dart';
import '../../../common/api/matrix_job_builder_mixin.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/artifacts.dart';
import '../../../common/inputs.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/steps/resolve_artifact_prefix_builder.dart';
import '../../../common/tools.dart';
import '../../../dart/dart_platform.dart';
import '../../../types/step.dart';

base mixin PackagecloudUploadConfig
    on JobConfig, WorkingDirectoryConfig, ResolveArtifactPrefixConfig {
  late final repository = inputContext(WorkflowInputs.packagecloudRepository);
  late final packagecloudToken = secretContext(
    WorkflowSecrets.packagecloudToken,
  );
}

// the current ubuntu LTS versions (excluding ESM)
enum UbuntuCodeName() implements IMatrixSelector {
  resolute,
  noble,
  jammy,
}

final class const CodeNameMatrixProperty()
    extends IMatrixProperty<UbuntuCodeName> {
  @override
  String get name => 'code-name';

  @override
  Object? valueFor(UbuntuCodeName include) => include.name;
}

class const PackagecloudUploadBuilder({
  required final PackagecloudUploadConfig config,
  required final CodeNameMatrixProperty codeName,
}) implements StepBuilder {
  @override
  Iterable<Step> build() => [
    ...const CheckoutBuilder(fetchDepth: 0).build(),
    ...ResolveArtifactPrefixBuilder(config: config).build(),
    Step.uses(
      name: 'Download debian package',
      uses: Tools.actionsDownloadArtifact,
      withArgs: {
        'name': Artifacts.name(
          prefix: config.resolvedPrefix,
          type: 'deb',
          platform: DartPlatform.linux,
        ),
        'path': 'deb',
      },
    ),
    Step.uses(
      name: 'Upload debian package to packagecloud',
      uses: Tools.lpenzGhactionPackagecloud,
      withArgs: {
        'repository': '${config.repository}/${codeName.expression}',
        'directory': 'deb',
      },
      env: {'PACKAGECLOUD_TOKEN': config.packagecloudToken.toString()},
    ),
  ];
}
