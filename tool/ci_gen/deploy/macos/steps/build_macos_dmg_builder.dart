import '../../../common/api/step_builder.dart';
import '../../../common/tools.dart';
import '../../../types/expression.dart';
import '../../../types/id.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

class BuildMacosDmgBuilder implements StepBuilder {
  static const getDmgTitleStepId = StepId('getDmgTitle');
  static final dmgTitleOutput = getDmgTitleStepId.output('title');

  final Expression workingDirectory;
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
              id: getDmgTitleStepId,
              name: 'Get DMG title from config',
              run: dmgTitleOutput.bashSetter(
                "jq -r '.title' '$dmgConfigPath'",
                isCommand: true,
              ),
              workingDirectory: workingDirectory.toString(),
            ),
            Step.run(
              name: 'Generate DMG file',
              run: "appdmg '$dmgConfigPath' "
                  "'build/macos/dmg/${dmgTitleOutput.expression}.dmg'",
              workingDirectory: workingDirectory.toString(),
            ),
          ],
        ).build(),
      ];
}
