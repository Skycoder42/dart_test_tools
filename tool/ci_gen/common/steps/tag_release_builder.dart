import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';
import 'checkout_builder.dart';
import 'release_entry_builder.dart';

class TagReleaseBuilder implements StepBuilder {
  static const versionStepId = StepId('version');
  static final updateOutput = versionStepId.output('update');
  static final versionOutput = versionStepId.output('version');

  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression tagPrefix;
  final Expression persistCredentials;
  final String? binaryArtifactsPattern;

  const TagReleaseBuilder({
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.tagPrefix,
    required this.persistCredentials,
    required this.binaryArtifactsPattern,
  });

  @override
  Iterable<Step> build() => [
        ...DartSdkBuilder(
          dartSdkVersion: dartSdkVersion,
        ).build(),
        ...CheckoutBuilder(
          persistCredentials: ExpressionOrValue.expression(persistCredentials),
        ).build(),
        Step.run(
          id: versionStepId,
          name: 'Check if a release should be created',
          run: '''
set -eo pipefail
package_version=\$(cat pubspec.yaml | yq e ".version" -)
git fetch --tags > /dev/null
tag_exists=\$(git tag -l "$tagPrefix\$package_version")

if [[ -z "\$tag_exists" ]]; then
  echo Release does not exist yet - creating release
  ${updateOutput.bashSetter('true')}
  ${versionOutput.bashSetter(r'$package_version')}
else
  echo Release already exists - skipping creation
  ${updateOutput.bashSetter('false')}
fi
''',
          workingDirectory: workingDirectory.toString(),
        ),
        if (binaryArtifactsPattern != null)
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
          workingDirectory: workingDirectory,
          tagPrefix: tagPrefix,
          versionUpdate: updateOutput.expression,
          files: binaryArtifactsPattern != null
              ? 'artifacts/$binaryArtifactsPattern/*'
              : null,
        ).build(),
      ];
}
