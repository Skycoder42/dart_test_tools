import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class ReleaseEntryBuilder implements StepBuilder {
  static const releaseContentStepId = StepId('release_content');
  static final releaseContentTagName = releaseContentStepId.output('tag_name');
  static final releaseContentReleaseName =
      releaseContentStepId.output('release_name');
  static final releaseContentBodyPath =
      releaseContentStepId.output('body_path');

  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;
  final Expression versionUpdate;
  final Expression? githubToken;
  final String? changelogExtra;
  final String? files;

  const ReleaseEntryBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.tagPrefix,
    required this.versionUpdate,
    this.githubToken,
    this.changelogExtra,
    this.files,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Activate cider',
          ifExpression: versionUpdate.eq(const Expression.literal('true')),
          run: 'dart pub global activate cider',
        ),
        Step.run(
          id: releaseContentStepId,
          name: 'Generate release content',
          ifExpression: versionUpdate.eq(const Expression.literal('true')),
          run: '''
set -e
package_name=\$(cat pubspec.yaml | yq e ".name" -)
package_version=\$(cat pubspec.yaml | yq e ".version" -)

tag_name="$tagPrefix\$package_version"
${releaseContentTagName.bashSetter(r'$tag_name')}

release_name="Release of package \$package_name - Version \$package_version"
${releaseContentReleaseName.bashSetter(r'$release_name')}

version_changelog_file=\$(mktemp)
echo "# Changelog" > \$version_changelog_file
dart pub global run cider describe "\$package_version" >> \$version_changelog_file
echo "" >> \$version_changelog_file${changelogExtra != null ? '\necho "$changelogExtra" >> \$version_changelog_file' : ''}
${releaseContentBodyPath.bashSetter(r'$version_changelog_file')}
''',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Create Release',
          ifExpression: versionUpdate.eq(const Expression.literal('true')),
          uses: Tools.softpropsActionGhRelease,
          withArgs: <String, dynamic>{
            if (githubToken != null) 'token': githubToken.toString(),
            'tag_name': releaseContentTagName.expression.toString(),
            'name': releaseContentReleaseName.expression.toString(),
            'body_path': releaseContentBodyPath.expression.toString(),
            if (files != null) 'files': files,
          },
        ),
      ];
}
