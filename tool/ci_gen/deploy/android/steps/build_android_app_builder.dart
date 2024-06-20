import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';
import '../../steps/generate_build_number_builder.dart';

class BuildAndroidAppBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression removePubspecOverrides;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression primaryLocale;
  final Expression dartDefines;
  final Expression keystore;
  final Expression keystorePassword;
  final String pubTool;
  final String runTool;

  const BuildAndroidAppBuilder({
    required this.workingDirectory,
    required this.removePubspecOverrides,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.primaryLocale,
    required this.dartDefines,
    required this.keystore,
    required this.keystorePassword,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
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
          buildTarget: 'appbundle',
          preBuildSteps: [
            Step.run(
              name: 'Prepare signing keystore',
              run: '''
set -eo pipefail
keystore_path='${Runner.temp}/app.keystore'
echo '$keystore' | openssl base64 -d > "\$keystore_path"
cat << EOF > android/key.properties
storeFile=\$keystore_path
password=$keystorePassword
EOF
''',
              workingDirectory: workingDirectory.toString(),
              shell: 'bash',
            ),
          ],
          cleanupPaths: [
            '$workingDirectory/android/key.properties',
            '${Runner.temp}/app.keystore',
          ],
          artifactDir: 'build/app/outputs',
          packageSteps: [
            Step.run(
              name: 'Generate Changelog',
              run: '''
set -eo pipefail
version=\$(yq e '.version' pubspec.yaml)
changelogs_dir='build/app/outputs/metadata/$primaryLocale/changelogs'
mkdir -p "\$changelogs_dir"
dart run cider describe "\$version" > "\$changelogs_dir/${GenerateBuildNumberBuilder.buildNumberOutput.expression}.txt"
''',
              workingDirectory: workingDirectory.toString(),
              shell: 'bash',
            ),
          ],
        ).build(),
      ];
}
