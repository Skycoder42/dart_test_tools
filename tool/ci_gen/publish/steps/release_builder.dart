import '../../common/api/step_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/release_entry_builder.dart';
import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class ReleaseBuilder implements StepBuilder {
  static const versionStepId = StepId('version');
  static final versionUpdate = versionStepId.output('update');
  static final versionOutput = versionStepId.output('version');

  final Expression dartSdkVersion;
  final Expression repository;
  final Expression workingDirectory;
  final Expression tagPrefix;

  ReleaseBuilder({
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
  ${versionOutput.bashSetter(r'$package_version')}
fi
''',
          workingDirectory: workingDirectory.toString(),
        ),
        ...ReleaseEntryBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          tagPrefix: tagPrefix,
          versionUpdate: versionUpdate.expression,
          changelogExtra: "The package and it's documentation are available at "
              r'[pub.dev](https://pub.dev/packages/$package_name/versions/$package_version).',
        ).build(),
      ];
}
