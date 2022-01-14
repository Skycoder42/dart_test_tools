import '../../common/api/step_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/release_entry_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class ReleaseBuilder implements StepBuilder {
  static const versionStepId = StepId('version');
  static late final versionUpdate = versionStepId.output('update');

  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;

  const ReleaseBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.tagPrefix,
  });

  @override
  Iterable<Step> build() => [
        ...CheckoutBuilder(
          repository: repository,
        ).build(),
        Step.run(
          id: versionStepId,
          name: 'Check if a release should be created',
          run: '''
set -e
package_version=\$(cat pubspec.yaml | yq e ".version" -)
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
          uses: 'actions/download-artifact@v2',
          withArgs: <String, dynamic>{
            'path': 'artifacts',
          },
        ),
        Step.run(
          name: 'Create asset archives',
          ifExpression:
              versionUpdate.expression.eq(const Expression.literal('true')),
          run: r'''
set -e
for artifact in $(ls); do
  zip -9 "$artifact.zip" "$artifact"/*.exe "$artifact"/*.js
done
''',
          workingDirectory: 'artifacts',
        ),
        ...ReleaseEntryBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          tagPrefix: tagPrefix,
          versionUpdate: versionUpdate.expression,
          files: 'artifacts/*.zip',
        ).build(),
      ];
}
