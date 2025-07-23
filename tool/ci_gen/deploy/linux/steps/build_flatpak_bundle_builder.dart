import '../../../common/api/job_config.dart';
import '../../../common/api/matrix_job_builder_mixin.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../common/inputs.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/steps/update_overrides_builder.dart';
import '../../../common/tools.dart';
import '../../../types/step.dart';
import '../../steps/generate_build_number_builder.dart';
import 'with_gpg_key.dart';

base mixin BuildFlatpakBundleConfig
    on
        JobConfig,
        UpdateOverridesConfig,
        GenerateBuildNumberConfig,
        WithGpgKeyConfig {
  late final sdkVersion = inputContext(WorkflowInputs.flatpakSdkVersion);
  late final bundleName = inputContext(WorkflowInputs.bundleName);
  late final manifestPath = inputContext(WorkflowInputs.manifestPath);

  @override
  bool get requireGpgKey => true;
}

enum FlatpakArchMatrixSelector implements IMatrixSelector { x86_64, aarch64 }

final class ArchMatrixProperty
    extends IMatrixProperty<FlatpakArchMatrixSelector> {
  const ArchMatrixProperty();

  @override
  String get name => 'arch';

  @override
  Object? valueFor(FlatpakArchMatrixSelector include) => include.name;
}

final class YqArchMatrixProperty
    extends IMatrixProperty<FlatpakArchMatrixSelector> {
  const YqArchMatrixProperty();

  @override
  String get name => 'yqArch';

  @override
  Object? valueFor(FlatpakArchMatrixSelector include) => switch (include) {
    FlatpakArchMatrixSelector.x86_64 => 'amd64',
    FlatpakArchMatrixSelector.aarch64 => 'arm64',
  };
}

class BuildFlatpakBundleBuilder implements StepBuilder {
  final BuildFlatpakBundleConfig config;
  final ArchMatrixProperty arch;
  final YqArchMatrixProperty yqArch;

  const BuildFlatpakBundleBuilder({
    required this.config,
    required this.arch,
    required this.yqArch,
  });

  @override
  Iterable<Step> build() => [
    Step.run(
      name: 'Manually install yq',
      run:
          '''
set -eo pipefail
curl -sSLo /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${yqArch.expression}
chmod +x /usr/bin/yq
''',
    ),
    Step.run(
      name: 'Download flatpak flutter SDK',
      run:
          'curl --fail-with-body -L -o /tmp/flutter.flatpak '
          "'https://github.com/Skycoder42/dart_test_tools/releases/download/flatpak-flutter-extension%2F${config.sdkVersion}/org.freedesktop.Sdk.Extension.flutter_${config.sdkVersion}_${arch.expression}.flatpak'",
    ),
    const Step.run(
      name: 'Install flatpak flutter SDK',
      run:
          'flatpak install --system -y --noninteractive '
          '/tmp/flutter.flatpak',
    ),
    ...const CheckoutBuilder().build(),
    ...UpdateOverridesBuilder(config: config, artifactTargetDir: '.').build(),
    ...GenerateBuildNumberBuilder(config: config, asEnv: true).build(),
    const Step.run(
      name: 'Prepare flatpak repo',
      run: '''
set -eo pipefail
ostree init --repo=repo --mode=archive
ostree --repo=repo config set core.min-free-space-size "1MB"
''',
    ),
    ...WithGpgKey(
      config: config,
      steps: [
        Step.uses(
          name: 'Build flatpak bundle',
          uses: Tools.flatpakFlatpakGithubActionsFlatpakBuilder,
          withArgs: {
            'bundle': config.bundleName.toString(),
            'manifest-path':
                '${config.workingDirectory}/${config.manifestPath}',
            'branch': Github.refName.toString(),
            'arch': arch.expression.toString(),
            'gpg-sign': config.gpgKeyId.toString(),
            'cache': false,
            'upload-artifact': false,
          },
        ),
      ],
    ).build(),
    Step.uses(
      name: 'Upload bundle artifact',
      uses: Tools.actionsUploadArtifact,
      withArgs: {
        'name': 'flatpak-bundle-${arch.expression}',
        'path': config.bundleName.toString(),
        'compression-level': 0,
        'if-no-files-found': 'error',
        'retention-days': 1,
      },
    ),
  ];
}
