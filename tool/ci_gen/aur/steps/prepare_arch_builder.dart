import '../../common/api/step_builder.dart';
import '../../common/steps/install_dart_test_tools_builder.dart';
import '../../types/step.dart';

class PrepareArchBuilder implements StepBuilder {
  const PrepareArchBuilder();

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Install pacman dependencies',
          run: 'pacman -Syu --noconfirm '
              'git openssh go-yq pacman-contrib namcap unzip',
        ),
        ...InstallDartTestToolsBuilder().build(),
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
