import '../../dart/steps/dart_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../contexts.dart';
import '../inputs.dart';
import '../tools.dart';
import 'checkout_builder.dart';
import 'release_entry_builder.dart';
import 'resolve_artifact_prefix_builder.dart';

base mixin TagReleaseConfig
    on JobConfig, ReleaseEntryConfig, ResolveArtifactPrefixConfig {
  late final dartSdkVersion = inputContext(WorkflowInputs.dartSdkVersion);
  late final persistCredentials = inputContext(
    WorkflowInputs.persistCredentials,
  );
  late final binaryArtifactsPattern = inputContext(
    WorkflowInputs.binaryArtifactsPattern,
  );
}

class TagReleaseBuilder implements StepBuilder {
  static const versionStepId = StepId('version');
  static final updateOutput = versionStepId.output('update');
  static final versionOutput = versionStepId.output('version');

  final TagReleaseConfig config;

  const TagReleaseBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...DartSdkBuilder(dartSdkVersion: config.dartSdkVersion).build(),
    ...CheckoutBuilder(
      persistCredentials: ExpressionOrValue.expression(
        config.persistCredentials,
      ),
    ).build(),
    Step.run(
      id: versionStepId,
      name: 'Check if a release should be created',
      run:
          '''
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
    ...ResolveArtifactPrefixBuilder(config: config).build(),
    Step.uses(
      name: 'Download all binary artifacts',
      ifExpression: updateOutput.expression.eq(
        const Expression.literal('true'),
      ),
      uses: Tools.actionsDownloadArtifact,
      withArgs: <String, dynamic>{
        'path': 'artifacts',
        'pattern': _binaryArtifactsPattern,
        'merge-multiple': true,
      },
    ),
    ...ReleaseEntryBuilder(
      config: config,
      versionUpdate: updateOutput.expression,
      files: 'artifacts/*',
    ).build(),
  ];

  /// The orphan-artifact pattern to attach to the release: the explicit
  /// `binaryArtifactsPattern` input if set, otherwise all bundle artifacts of
  /// the current package (`<artifactPrefix>-*`).
  String get _binaryArtifactsPattern =>
      (config.binaryArtifactsPattern |
              Functions.format('{0}-*', [config.resolvedPrefix]))
          .toString();
}
