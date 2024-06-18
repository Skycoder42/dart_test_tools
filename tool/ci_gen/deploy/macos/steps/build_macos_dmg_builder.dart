import '../../../common/api/step_builder.dart';
import '../../../common/tools.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

class BuildMacosDmgBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression removePubspecOverrides;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression dmgConfigPath;
  final Expression dartDefines;
  final String pubTool;
  final String runTool;

  const BuildMacosDmgBuilder({
    required this.workingDirectory,
    required this.removePubspecOverrides,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.dmgConfigPath,
    required this.dartDefines,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        const Step.uses(
          name: 'Setup NodeJS',
          uses: Tools.actionsSetupNode,
        ),
        const Step.run(
          name: 'Install appdmg',
          run: 'npm install -g appdmg',
        ),
        ...BuildAppBuilder(
          workingDirectory: workingDirectory,
          removePubspecOverrides:
              ExpressionOrValue.expression(removePubspecOverrides),
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          buildNumberArgs: buildNumberArgs,
          dartDefines: dartDefines,
          pubTool: pubTool,
          runTool: runTool,
          buildTarget: 'macos',
          artifactDir: 'build/macos/dmg',
          packageSteps: [
            Step.run(
              name: 'Generate DMG image',
              run: '''
set -eo pipefail
title=\$(jq -r '.title' '$dmgConfigPath')
mkdir -p build/macos/dmg
appdmg '$dmgConfigPath' "build/macos/dmg/\$title.dmg"
''',
              workingDirectory: workingDirectory.toString(),
            ),
          ],
        ).build(),
      ];
}
