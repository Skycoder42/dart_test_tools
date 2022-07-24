import '../../common/api/step_builder.dart';
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
          name: 'Create build user',
          run: 'useradd -m build',
        ),
      ];
}
