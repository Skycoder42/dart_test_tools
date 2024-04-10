import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/steps/install_dart_test_tools_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'build_app_builder.dart';
import 'generate_build_number_builder.dart';

class BuildAndroidAppBuilder implements StepBuilder {
  final Expression workingDirectory;
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
        ...InstallDartTestToolsBuilder().build(),
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          releaseMode: true,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        ...GenerateBuildNumberBuilder(
          buildNumberArgs: buildNumberArgs,
          workingDirectory: workingDirectory,
        ).build(),
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
        Step.run(
          name: 'Prepare signing keystore',
          run: '''
set -eo pipefail
keystore_path="${Runner.temp}/app.keystore"
echo '$keystore' | openssl base64 -d > "\$keystore_path"
cat << EOF > android/key.properties
storeFile=\$keystore_path
password=$keystorePassword
EOF
''',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        ...BuildAppBuilder(
          buildNumber: GenerateBuildNumberBuilder.buildNumberOutput.expression,
          workingDirectory: workingDirectory,
          dartDefines: dartDefines,
          buildTarget: 'appbundle',
          debugInfoDir: 'build/app/outputs',
        ).build(),
        Step.run(
          name: 'Cleanup keystore and properties',
          ifExpression: Expression.always,
          continueOnError: true,
          run: '''
rm -rf android/key.properties
rm -rf "${Runner.temp}/app.keystore"
''',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.uses(
          name: 'Upload app bundle and debug info',
          uses: Tools.actionsUploadArtifact,
          withArgs: {
            'name': 'android-app',
            'path': 'build/app/outputs',
            'retention-days': 1,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
