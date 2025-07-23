import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/inputs.dart';
import '../../../common/tools.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

base mixin BuildMacosDmgConfig on JobConfig, BuildAppConfig {
  late final dmgConfigPath = inputContext(WorkflowInputs.dmgConfigPath);

  @override
  String get buildTarget => 'macos';

  @override
  String get artifactDir => 'build/macos/dmg';
}

class BuildMacosDmgBuilder implements StepBuilder {
  final BuildMacosDmgConfig config;

  const BuildMacosDmgBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    const Step.uses(name: 'Setup NodeJS', uses: Tools.actionsSetupNode),
    const Step.run(name: 'Install appdmg', run: 'npm install -g appdmg'),
    ...BuildAppBuilder(
      config: config,
      packageSteps: [
        Step.run(
          name: 'Generate DMG image',
          run:
              '''
set -eo pipefail
title=\$(jq -r '.title' '${config.dmgConfigPath}')
mkdir -p build/macos/dmg
appdmg '${config.dmgConfigPath}' "build/macos/dmg/\$title.dmg"
''',
          workingDirectory: config.workingDirectory.toString(),
        ),
      ],
    ).build(),
  ];
}
