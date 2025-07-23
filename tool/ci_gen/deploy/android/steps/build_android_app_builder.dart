import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../common/inputs.dart';
import '../../../common/secrets.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';
import '../../steps/generate_build_number_builder.dart';

base mixin BuildAndroidAppConfig on JobConfig, BuildAppConfig {
  late final primaryLocale = inputContext(WorkflowInputs.primaryLocale);
  late final keystore = secretContext(WorkflowSecrets.keystore);
  late final keystorePassword = secretContext(WorkflowSecrets.keystorePassword);

  @override
  String get buildTarget => 'appbundle';

  @override
  String get artifactDir => 'build/app/outputs';
}

class BuildAndroidAppBuilder implements StepBuilder {
  final BuildAndroidAppConfig config;

  const BuildAndroidAppBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...BuildAppBuilder(
      config: config,
      preBuildSteps: [
        Step.run(
          name: 'Prepare signing keystore',
          run:
              '''
set -eo pipefail
keystore_path='${Runner.temp}/app.keystore'
echo '${config.keystore}' | openssl base64 -d > "\$keystore_path"
cat << EOF > android/key.properties
storeFile=\$keystore_path
password=${config.keystorePassword}
EOF
''',
          workingDirectory: config.workingDirectory.toString(),
          shell: 'bash',
        ),
      ],
      cleanupPaths: [
        '${config.workingDirectory}/android/key.properties',
        '${Runner.temp}/app.keystore',
      ],
      packageSteps: [
        Step.run(
          name: 'Generate Changelog',
          run:
              '''
set -eo pipefail
version=\$(yq e '.version' pubspec.yaml)
changelogs_dir='build/app/outputs/metadata/${config.primaryLocale}/changelogs'
mkdir -p "\$changelogs_dir"
dart run cider describe "\$version" > "\$changelogs_dir/${GenerateBuildNumberBuilder.buildNumberOutput.expression}.txt"
''',
          workingDirectory: config.workingDirectory.toString(),
          shell: 'bash',
        ),
      ],
    ).build(),
  ];
}
