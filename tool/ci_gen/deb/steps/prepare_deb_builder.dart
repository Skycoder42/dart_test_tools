import '../../common/api/step_builder.dart';
import '../../common/globals.dart';
import '../../types/step.dart';

class PrepareDebBuilder implements StepBuilder {
  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Add dart repository',
          run: '''
set -eo pipefail
wget -qO- 'https://dl-ssl.google.com/linux/linux_signing_key.pub' | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
''',
        ),
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
          run: 'sudo apt-get install -y dart makedeb',
        ),
        const Step.run(
          name: 'Install dart_test_tools',
          run:
              'dart pub global activate dart_test_tools ^$dartTestToolsVersion',
        ),
        Step.run(
          name: 'Disable stripping',
          run: r'''
set -eo pipefail
strip_path=$(which strip)
sudo rm -f "$strip_path"
cat << EOF | sudo tee "$strip_path" > /dev/null
#!/bin/bash
echo "DISABLED: strip $@"
EOF
sudo chmod a+x "$strip_path"
''',
        ),
      ];
}
