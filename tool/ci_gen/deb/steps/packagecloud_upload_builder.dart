import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
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

enum UbuntuCodeName implements IMatrixSelector { noble, jammy }

final class CodeNameMatrixProperty extends IMatrixProperty<UbuntuCodeName> {
  const CodeNameMatrixProperty();

  @override
  String get name => 'code-name';

  @override
  Object? valueFor(UbuntuCodeName include) => include.name;
}

class PackagecloudUploadBuilder implements StepBuilder {
  final PackagecloudUploadConfig config;
  final CodeNameMatrixProperty codeName;

  const PackagecloudUploadBuilder({
    required this.config,
    required this.codeName,
  });

  @override
  Iterable<Step> build() => [
    const Step.uses(
      name: 'Download debian package',
      uses: Tools.actionsDownloadArtifact,
      withArgs: {'name': 'debian-package', 'path': 'deb'},
    ),
    Step.run(
      name: 'Append ${codeName.expression} to debian packages',
      run: '''
set -eo pipefail
for file in deb/*.deb; do
  mv "\$file" "\${file%.deb}_${codeName.expression}.deb"
done
''',
    ),
    Step.uses(
      name: 'Upload debian package to packagecloud',
      uses: Tools.lpenzGhactionPackagecloud,
      withArgs: {'repository': '${config.repository}/${codeName.expression}'},
      env: {'PACKAGECLOUD_TOKEN': config.packagecloudToken.toString()},
    ),
  ];
}
