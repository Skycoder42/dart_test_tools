import '../../common/actions/install_tools_action_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/step.dart';

base mixin PrepareArchConfig on JobConfig {
  late final dartSdkVersion = inputContext(WorkflowInputs.dartSdkVersion);
}

class PrepareArchBuilder implements StepBuilder {
  final PrepareArchConfig config;

  const PrepareArchBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    const Step.run(
      name: 'Install pacman dependencies',
      run:
          'pacman -Syu --noconfirm '
          'git openssh go-yq pacman-contrib namcap unzip base-devel',
    ),
    Step.run(
      name: 'Install powershell',
      run: '''
set -euo pipefail
git clone https://aur.archlinux.org/powershell-bin.git
cd powershell-bin
su nobody -c makepkg -f
pacman -U *.pkg.tar.*
''',
      workingDirectory: Runner.temp.toString(),
    ),
    ...DartSdkBuilder(dartSdkVersion: config.dartSdkVersion).build(),
    InstallToolsActionBuilder.step(withDartTestTools: true),
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
