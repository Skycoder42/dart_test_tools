import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

base mixin BuildWindowsInstallerConfig on JobConfig, BuildAppConfig {
  @override
  String get buildTarget => 'windows';

  @override
  String get artifactDir => 'build/windows/msix';
}

class BuildWindowsInstallerBuilder implements StepBuilder {
  final BuildWindowsInstallerConfig config;

  const BuildWindowsInstallerBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        ...BuildAppBuilder(
          config: config,
          packageSteps: [
            Step.run(
              name: 'Create msix package',
              run: 'dart run msix:create --release --store '
                  '--build-windows false '
                  r'--output-path build\windows\msix',
              workingDirectory: config.workingDirectory.toString(),
            ),
          ],
        ).build(),
      ];
}
