import '../../common/api/step_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/release_data_builder.dart';
import '../../common/steps/release_entry_builder.dart';
import '../../common/tools.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class ReleaseBuilder implements StepBuilder {
  static const versionStepId = StepId('version');
  static final versionUpdate = versionStepId.output('update');

  final Expression dartSdkVersion;
  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;

  const ReleaseBuilder({
    required this.dartSdkVersion,
    required this.repository,
    required this.workingDirectory,
    required this.tagPrefix,
  });

  @override
  Iterable<Step> build() => [
        ...DartSdkBuilder(
          dartSdkVersion: dartSdkVersion,
        ).build(),
        ...CheckoutBuilder(
          repository: repository,
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
  ${versionUpdate.bashSetter('true')}
else
  echo Release already exists - skipping creation
  ${versionUpdate.bashSetter('false')}
fi
''',
        ),
        Step.uses(
          name: 'Download all binary artifacts',
          ifExpression:
              versionUpdate.expression.eq(const Expression.literal('true')),
          uses: Tools.actionsDownloadArtifact,
          withArgs: <String, dynamic>{
            'path': 'artifacts',
          },
        ),
        Step.run(
          name: 'Create asset archives',
          ifExpression:
              versionUpdate.expression.eq(const Expression.literal('true')),
          run: r'''
set -eo pipefail
for artifact in $(find . -type d -name "binaries-*"); do
  zip -9 "$artifact.zip" "$artifact"/*.exe "$artifact"/*.js
done
''',
          workingDirectory: 'artifacts',
        ),
        ...ReleaseDataBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          tagPrefix: tagPrefix,
          versionUpdate: versionUpdate.expression,
          bodyAsFile: true,
        ).build(),
        ...ReleaseEntryBuilder(
          versionUpdate: versionUpdate.expression,
          tag: ReleaseDataBuilder.releaseContentTagName.expression,
          name: ReleaseDataBuilder.releaseContentReleaseName.expression,
          body: ReleaseDataBuilder.releaseContentBodyContent.expression,
          bodyAsFile: true,
          files: 'artifacts/*.zip',
        ).build()
      ];
}
