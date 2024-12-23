import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../inputs.dart';
import '../tools.dart';
import 'checkout_builder.dart';
import 'release_entry_builder.dart';

base mixin TagReleaseConfig on JobConfig, ReleaseEntryConfig {
  late final dartSdkVersion = inputContext(WorkflowInputs.dartSdkVersion);
  late final persistCredentials =
      inputContext(WorkflowInputs.persistCredentials);
  String? get binaryArtifactsPattern;
}

class TagReleaseBuilder implements StepBuilder {
  static const versionStepId = StepId('version');
  static final updateOutput = versionStepId.output('update');
  static final versionOutput = versionStepId.output('version');

  final TagReleaseConfig config;

  const TagReleaseBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        ...DartSdkBuilder(
          dartSdkVersion: config.dartSdkVersion,
        ).build(),
        ...CheckoutBuilder(
          persistCredentials:
              ExpressionOrValue.expression(config.persistCredentials),
        ).build(),
        Step.run(
          id: versionStepId,
          name: 'Check if a release should be created',
          run: '''
set -eo pipefail
package_version=\$(cat pubspec.yaml | yq e ".version" -)
git fetch --tags > /dev/null
tag_exists=\$(git tag -l "${config.tagPrefix}\$package_version")

if [[ -z "\$tag_exists" ]]; then
  echo Release does not exist yet - creating release
  ${updateOutput.bashSetter('true')}
  ${versionOutput.bashSetter(r'$package_version')}
else
  echo Release already exists - skipping creation
  ${updateOutput.bashSetter('false')}
fi
''',
          workingDirectory: config.workingDirectory.toString(),
        ),
        if (config.binaryArtifactsPattern
            case final String binaryArtifactsPattern)
          Step.uses(
            name: 'Download all binary artifacts',
            ifExpression:
                updateOutput.expression.eq(const Expression.literal('true')),
            uses: Tools.actionsDownloadArtifact,
            withArgs: <String, dynamic>{
              'path': 'artifacts',
              'pattern': binaryArtifactsPattern,
            },
          ),
        ...ReleaseEntryBuilder(
          config: config,
          versionUpdate: updateOutput.expression,
          files: config.binaryArtifactsPattern != null
              ? 'artifacts/${config.binaryArtifactsPattern}/*'
              : null,
        ).build(),
      ];
}
