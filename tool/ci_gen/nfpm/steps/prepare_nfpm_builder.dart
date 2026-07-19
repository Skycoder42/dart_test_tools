import '../../common/actions/install_tools_action_builder.dart';
import '../../common/api/step_builder.dart';
import '../../types/step.dart';

class PrepareNfpmBuilder implements StepBuilder {
  const PrepareNfpmBuilder();

  @override
  Iterable<Step> build() => [
    const Step.run(
      name: 'Install nfpm',
      run: '''
set -eo pipefail
echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' | sudo tee /etc/apt/sources.list.d/goreleaser.list
sudo apt-get update
sudo apt-get install -y nfpm
''',
    ),
    InstallToolsActionBuilder.step(withDartTestTools: true),
  ];
}
