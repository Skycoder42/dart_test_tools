import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/api/working_directory_config.dart';
import '../../../common/contexts.dart';
import '../../../common/inputs.dart';
import '../../../common/secrets.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/tools.dart';
import '../../../types/id.dart';
import '../../../types/step.dart';

base mixin DeployAndroidConfig on JobConfig, WorkingDirectoryConfig {
  late final googlePlayTrack = inputContext(WorkflowInputs.googlePlayTrack);
  late final googlePlayReleaseStatus = inputContext(
    WorkflowInputs.googlePlayReleaseStatus,
  );
  late final googlePlayKey = secretContext(WorkflowSecrets.googlePlayKey);
}

class DeployAndroidAppBuilder implements StepBuilder {
  static const detectPackageNameStepId = StepId('detectPackageName');
  static final packageNameOutput = detectPackageNameStepId.output(
    'packageName',
  );

  final DeployAndroidConfig config;

  const DeployAndroidAppBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...const CheckoutBuilder(fetchDepth: 0).build(),
    const Step.uses(
      name: 'Download android app artifact',
      uses: Tools.actionsDownloadArtifact,
      withArgs: {'name': 'app-deployment-appbundle', 'path': 'build'},
    ),
    Step.run(
      id: detectPackageNameStepId,
      name: 'Detect android package name',
      run: packageNameOutput.bashSetter(
        'cat android/app/build.gradle | grep \'applicationId = "\' | cut -d \'"\' -f2',
        isCommand: true,
      ),
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    Step.run(
      name: 'Prepare Google Play key',
      run:
          "echo '${config.googlePlayKey}' > '${Runner.temp}/fastlane-key-file.json'",
    ),
    Step.run(
      name: 'Deploy to Google Play',
      run:
          'fastlane upload_to_play_store '
          "--json_key '${Runner.temp}/fastlane-key-file.json' "
          "--package_name '${packageNameOutput.expression}' "
          "--track '${config.googlePlayTrack}' "
          "--release_status '${config.googlePlayReleaseStatus}' "
          '--aab build/bundle/release/app-release.aab '
          '--mapping build/mapping/release/mapping.txt '
          '--metadata_path build/metadata',
    ),
    Step.run(
      name: 'Cleanup Google Play key',
      ifExpression: Functions.always,
      continueOnError: true,
      run: 'rm -f "${Runner.temp}/fastlane-key-file.json"',
    ),
  ];
}
