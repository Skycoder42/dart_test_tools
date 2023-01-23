import '../../common/api/step_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/release_data_builder.dart';
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
fi
''',
          workingDirectory: workingDirectory.toString(),
        ),
        ...ReleaseDataBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          tagPrefix: tagPrefix,
          versionUpdate: versionUpdate.expression, // TODO check equals here
          changelogExtra: "The package and it's documentation are available at "
              r'[pub.dev](https://pub.dev/packages/$package_name/versions/$package_version).',
        ).build(),
        Step.uses(
          name: 'Dispatch release event',
          ifExpression: _hasUpdate,
          uses: Tools.peterEvansRepositoryDispatch,
          withArgs: <String, dynamic>{
            // TODO constant
            'event-type': 'de.skycoder42.dart_test_tools.create-release',
            'client-payload': _buildClientPayload().toString(),
          },
        ),
      ];

  Expression get _hasUpdate =>
      versionUpdate.expression.eq(const Expression.literal('true'));

  Expression _buildClientPayload() {
    final payload = {
      'ref': const Expression('github.ref'),
      'tag': ReleaseDataBuilder.releaseContentTagName.expression,
      'release': ReleaseDataBuilder.releaseContentReleaseName.expression,
      'body': ReleaseDataBuilder.releaseContentBodyContent.expression,
    };
    final encodedPayload = payload.entries
        .map((param) => '${param.key}: ${param.value.value}')
        .join(', ');
    return Expression('toJson({$encodedPayload})');
  }
}
