import 'dart:io';

import '../../common/jobs/analyze_job_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterAnalyzeJobBuilder extends AnalyzeJobBuilder
    with FlutterSdkJobBuilderMixin {
  @override
  final Expression flutterSdkChannel;
  @override
  final Expression javaJdkVersion;

  const FlutterAnalyzeJobBuilder({
    required this.flutterSdkChannel,
    required this.javaJdkVersion,
    required super.workingDirectory,
    required super.artifactDependencies,
    required super.buildRunner,
    required super.buildRunnerArgs,
    required super.removePubspecOverrides,
    required super.analyzeImage,
    required super.panaScoreThreshold,
  });

  @override
  Iterable<Step> buildAnalyzeSteps() => [
        Step.run(
          name: 'Static analysis',
          run: 'flutter analyze',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Apply custom_lint bug workaround',
          run: '''
set -eo pipefail

rm -rf windows/flutter/ephemeral/.plugin_symlinks

flutter_gen_dir=.dart_tool/flutter_gen
if [ ! -d "\$flutter_gen_dir" ]; then
  exit 0
fi

echo "::debug::Applying workaround for https://github.com/invertase/dart_custom_lint/issues/268"
cd "\$flutter_gen_dir"
yq -i '.environment.sdk="^${Platform.version.split(' ').first}"' pubspec.yaml
dart pub get
''',
          shell: 'bash',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
