import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import 'upload_sentry_symbols.dart';

class DeployAndroidAppBuilder implements StepBuilder {
  static const detectPackageNameStepId = StepId('detectPackageName');
  static final packageNameOutput =
      detectPackageNameStepId.output('packageName');

  final Expression workingDirectory;
  final Expression sentryAuthToken;
  final Expression buildNumber;
  final Expression googlePlayTrack;
  final Expression googlePlayReleaseStatus;
  final Expression googlePlayKey;
  final String pubTool;

  const DeployAndroidAppBuilder({
    required this.workingDirectory,
    required this.sentryAuthToken,
    required this.buildNumber,
    required this.googlePlayTrack,
    required this.googlePlayReleaseStatus,
    required this.googlePlayKey,
    required this.pubTool,
  });

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Install fastlane',
          run: 'brew install fastlane',
        ),
        ...const CheckoutBuilder(fetchDepth: 0).build(),
        const Step.uses(
          name: 'Download android app artifact',
          uses: Tools.actionsDownloadArtifact,
          withArgs: {
            'name': 'android-app',
            'path': 'build',
          },
        ),
        Step.run(
          id: detectPackageNameStepId,
          name: 'Detect android package name',
          run: '${packageNameOutput.bashSetter(
            'cat android/app/build.gradle | grep \'applicationId "\' | cut -d \'"\' -f2',
            isCommand: true,
          )}',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.run(
          name: 'Prepare Google Play key',
          run:
              'echo \'$googlePlayKey\' > "${Runner.temp}/fastlane-key-file.json"',
        ),
        Step.run(
          name: 'Deploy to Google Play',
          run: 'fastlane upload_to_play_store '
              '--json_key "${Runner.temp}/fastlane-key-file.json" '
              "--package_name '${packageNameOutput.expression}' "
              "--track '$googlePlayTrack' "
              "--release_status '$googlePlayReleaseStatus' "
              '--aab build/bundle/release/app-release.aab '
              '--mapping build/mapping/release/mapping.txt '
              '--metadata_path build/metadata',
        ),
        Step.run(
          name: 'Cleanup Google Play key',
          ifExpression: Expression.always,
          run: 'rm -f "${Runner.temp}/fastlane-key-file.json"',
        ),
        ...UploadSentrySymbolsBuilder(
          workingDirectory: workingDirectory,
          sentryAuthToken: sentryAuthToken,
          sentryDist: buildNumber,
          pubTool: pubTool,
        ).build(),
      ];
}
