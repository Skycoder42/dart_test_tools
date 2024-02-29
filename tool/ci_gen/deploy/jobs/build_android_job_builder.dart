import '../../common/jobs/sdk_job_builder.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../steps/build_android_app_builder.dart';

final class BuildAndroidJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;

  const BuildAndroidJobBuilder({
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
  });

  @override
  JobId get id => const JobId('build');

  @override
  Job build() => Job(
        name: 'Build app',
        runsOn: RunsOn.ubuntuLatest.id,
        steps: [
          ...buildSetupSdkSteps(
            buildPlatform: Expression.fake('android'),
            enforceJdk: true,
          ),
          ...BuildAndroidAppBuilder(
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            pubTool: pubTool,
            runTool: runTool,
          ).build(),
        ],
      );
}

/// TODO following steps:
/// - id: generateBuildNumber
///   name: Generate build number
///   run: dart run tool/generate_build_number.dart
/// - name: Generate Changelog
///   run: |
///     set -eo pipefail
///
///     changelogs_dir=build/app/outputs/metadata/en-US/changelogs
///     mkdir -p "$changelogs_dir"
///
///     dart run cider describe '${{ needs.release.outputs.releaseVersion }}' > "$changelogs_dir/${{ steps.generateBuildNumber.outputs.buildNumber }}.txt"
/// - name: Prepare signing keystore
///   run: tool/prepare_keystore.sh create
///   env:
///     KEYSTORE: ${{ secrets.KEYSTORE }}
///     KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
/// - name: Build android app bundle
///   run: >-
///     flutter build appbundle
///     --release
///     --build-number=${{ steps.generateBuildNumber.outputs.buildNumber }}
///     --obfuscate --split-debug-info=build/app/outputs/debug-info
///     --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
/// - name: Upload app and debug info
///   uses: actions/upload-artifact@v4
///   with:
///     name: android-app
///     path: build/app/outputs
///     retention-days: 1
///     if-no-files-found: error
/// - name: Delete keystore and properties
///   if: always()
///   continue-on-error: true
///   run: tool/prepare_keystore.sh delete
