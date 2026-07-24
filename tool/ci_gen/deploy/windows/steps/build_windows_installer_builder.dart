import '../../../common/api/job_config.dart';
import '../../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/artifacts.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

base mixin BuildWindowsInstallerConfig on JobConfig, BuildAppConfig {
  @override
  String get buildTarget => 'windows';

  @override
  String get artifactDir => 'build/windows/msix';

  @override
  ArtifactType get artifactType => ArtifactType.msix;

  @override
  IPlatformMatrixSelector get buildPlatform => FlutterPlatform.windows;
}

class BuildWindowsInstallerBuilder implements StepBuilder {
  final BuildWindowsInstallerConfig config;

  const BuildWindowsInstallerBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...BuildAppBuilder(
      config: config,
      packageSteps: [
        Step.run(
          name: 'Create msix package',
          run:
              'dart run msix:create --release --store '
              '--build-windows false '
              r'--output-path build\windows\msix',
          workingDirectory: config.workingDirectory.toString(),
        ),
      ],
    ).build(),
  ];
}
