import '../../common/api/step_builder.dart';
import '../../common/globals.dart';
import '../../types/step.dart';

class PrepareArchBuilder implements StepBuilder {
  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Install pacman dependencies',
          run: 'pacman -Sy --noconfirm '
              'git openssh go-yq pacman-contrib dart namcap',
        ),
        const Step.run(
          name: 'Install dart_test_tools',
          run: 'dart global activate dart_test_tools ^$dartTestToolsVersion',
        ),
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
