import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';

class ReleaseEntryBuilder implements StepBuilder {
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
  final Expression versionUpdate;
  final String? changelogExtra;
  final String? files;

  const ReleaseEntryBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.tagPrefix,
    required this.versionUpdate,
    this.changelogExtra,
    this.files,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          id: releaseContentStepId,
          name: 'Generate release content',
          ifExpression: versionUpdate.eq(const Expression.literal('true')),
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
echo "" > \$version_changelog_file${changelogExtra != null ? '\necho "$changelogExtra" > \$version_changelog_file' : ''}
${releaseContentBodyPath.bashSetter('\$version_changelog_file')}
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Create Release',
          ifExpression: versionUpdate.eq(const Expression.literal('true')),
          uses: 'softprops/action-gh-release@v1',
          withArgs: {
            'tag_name': releaseContentTagName.expression.toString(),
            'name': releaseContentReleaseName.expression.toString(),
            'body_path': releaseContentBodyPath.expression.toString(),
            if (files != null) 'files': files,
          },
        ),
      ];
}
