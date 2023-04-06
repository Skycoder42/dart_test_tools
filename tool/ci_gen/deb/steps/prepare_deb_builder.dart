import '../../common/api/step_builder.dart';
import '../../types/env.dart';
import '../../types/step.dart';

class PrepareDebBuilder implements StepBuilder {
  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Add dart repository',
          run: '''
set -eo pipefail
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt-get update
''',
        ),
        Step.run(
          name: 'Install dart',
          run: 'sudo apt-get install -y dart',
        ),
        Step.run(
          name: 'Install makedeb',
          env: const Env({
            'MAKEDEB_RELEASE': 'makedeb',
          }),
          run:
              'bash -c "\$(wget -qO - \'https://shlink.makedeb.org/install\')"',
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
