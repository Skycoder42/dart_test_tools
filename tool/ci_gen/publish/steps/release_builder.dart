import '../../common/api/step_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class ReleaseBuilder implements StepBuilder {
  static const versionStepId = StepId('version');
  static late final versionUpdate = versionStepId.output('update');

  static const releaseContentStepId = StepId('release_content');
  static late final releaseContentTagName =
      releaseContentStepId.output('tag_name');
  static late final releaseContentReleaseName =
      releaseContentStepId.output('release_name');
  static late final releaseContentBodyPath =
      releaseContentStepId.output('body_path');

  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;

  ReleaseBuilder({
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
          name: 'Check if package should be published',
          run: '''
set -e
package_name=\$(cat pubspec.yaml | yq e ".name" -)
package_version=\$(cat pubspec.yaml | yq e ".version" -)
version_exists_query=".versions | .[] | select(.version == \\"\$package_version\\") | .version"

pub_info_file=\$(mktemp)
curl -sSLo \$pub_info_file \\
  -H "Accept: application/vnd.pub.v2+json" \\
  -H "Accept-Encoding: identity" \\
  "https://pub.dev/api/packages/\$package_name"

if cat \$pub_info_file | jq -e "\$version_exists_query" > /dev/null; then
  echo Version already exists on pub.dev - skipping deployment
  ${versionUpdate.bashSetter('false')}
else
  echo Version does not exists on pub.dev - creating release
  ${versionUpdate.bashSetter('true')}
fi
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          id: releaseContentStepId,
          name: 'Generate release content',
          ifExpression:
              versionUpdate.expression.eq(const Expression.literal('true')),
          run: '''
set -e
package_name=\$(cat pubspec.yaml | yq e ".name" -)
package_version=\$(cat pubspec.yaml | yq e ".version" -)

tag_name="$tagPrefix\$package_version"
${releaseContentTagName.bashSetter('\$tag_name')}

release_name="Release of package \$package_name - Version \$package_version"
${releaseContentReleaseName.bashSetter('\$release_name')}

version_changelog_file=\$(mktemp)
echo "## Changelog" > \$version_changelog_file
cat CHANGELOG.md | sed '/^## \\['\$package_version'\\].*\$/,/^## \\[/!d;//d' >> \$version_changelog_file
echo "" > \$version_changelog_file
echo "The package and it's documentation are available at [pub.dev](https://pub.dev/packages/\$package_name/versions/\$package_version)." > \$version_changelog_file
${releaseContentBodyPath.bashSetter('\$version_changelog_file')}
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Create Release',
          ifExpression:
              versionUpdate.expression.eq(const Expression.literal('true')),
          env: {
            'GITHUB_TOKEN': const Expression('secrets.GITHUB_TOKEN').toString(),
          },
          uses: 'actions/create-release@v1',
          withArgs: {
            'tag_name': releaseContentTagName.expression.toString(),
            'release_name': releaseContentReleaseName.expression.toString(),
            'body_path': releaseContentBodyPath.expression.toString(),
          },
        ),
      ];
}
