import '../../common/api/step_builder.dart';
import '../../common/steps/install_dart_test_tools_builder.dart';
import '../../types/step.dart';

class PrepareDebBuilder implements StepBuilder {
  const PrepareDebBuilder();

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Add makedeb repository',
          run: '''
set -eo pipefail
wget -qO- 'https://proget.makedeb.org/debian-feeds/makedeb.pub' | sudo gpg --dearmor -o /usr/share/keyrings/makedeb-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.makedeb.org/ makedeb main' | sudo tee /etc/apt/sources.list.d/makedeb.list
''',
        ),
        Step.run(
          name: 'Refresh packages cache',
          run: 'sudo apt-get update',
        ),
        Step.run(
          name: 'Install needed packages',
          run: 'sudo apt-get install -y makedeb',
        ),
        ...InstallDartTestToolsBuilder().build(),
      ];
}
