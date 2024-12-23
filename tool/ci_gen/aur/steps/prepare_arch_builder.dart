import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/steps/install_dart_test_tools_builder.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

base mixin PrepareArchConfig on JobConfig {
  late Expression dartSdkVersion;
}

class PrepareArchBuilder implements StepBuilder {
  final PrepareArchConfig config;

  const PrepareArchBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Install pacman dependencies',
          run: 'pacman -Syu --noconfirm '
              'git openssh go-yq pacman-contrib namcap unzip',
        ),
        ...DartSdkBuilder(
          dartSdkVersion: config.dartSdkVersion,
        ).build(),
        ...const InstallDartTestToolsBuilder().build(),
        const Step.run(
          name: 'Create build user',
          run: '''
set -eo pipefail
useradd -m build
echo 'build ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
''',
        ),
      ];
}
