import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/artifacts.dart';
import '../../../common/inputs.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/tools.dart';
import '../../../flutter/flutter_platform.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';
import 'with_gpg_key.dart';

base mixin DeployToPagesConfig on JobConfig, WithGpgKeyConfig {
  late final artifactPrefix = inputContext(WorkflowInputs.artifactPrefix);

  @override
  bool get requireGpgKey => false;

  /// The minimatch pattern of flatpak bundles to download and deploy.
  ///
  /// Unlike the other deploy targets, the pages job only checks out the
  /// `gh-pages` branch and thus has no source `pubspec.yaml` to derive the
  /// prefix from. So an empty `artifactPrefix` falls back to the `*` wildcard,
  /// matching every package's flatpak bundles (correct for the common
  /// single-package pipeline; set `artifactPrefix` to disambiguate otherwise).
  String get artifactPattern => Artifacts.pattern(
    prefix: artifactPrefix | const Expression.literal('*'),
    type: ArtifactType.flatpak,
    platform: FlutterPlatform.linux,
  );
}

class DeployToPagesBuilder implements StepBuilder {
  static const _gpPagesBranch = 'gh-pages';

  final DeployToPagesConfig config;

  DeployToPagesBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...const CheckoutBuilder(
      gitRef: Expression.fake(_gpPagesBranch),
      path: 'repo',
      persistCredentials: ExpressionOrValue.value(true),
    ).build(),
    Step.uses(
      name: 'Download flatpak bundle artifacts',
      uses: Tools.actionsDownloadArtifact,
      withArgs: {'pattern': config.artifactPattern, 'path': 'bundles'},
    ),
    ...WithGpgKey(
      config: config,
      steps: [
        Step.run(
          name: 'Import bundles into repository',
          run:
              '''
set -eo pipefail
for bundle in bundles/*/*.flatpak; do
  echo "Importing \$bundle..."
  flatpak build-import-bundle \\
    --update-appstream \\
    --gpg-sign='${config.gpgKeyId}' \\
    repo \\
    "\$bundle"
done
''',
        ),
        Step.run(
          name: 'Generate static deltas',
          run:
              'flatpak build-update-repo '
              '--generate-static-deltas '
              '--prune '
              "--gpg-sign='${config.gpgKeyId}' "
              'repo',
        ),
      ],
    ).build(),
    Step.uses(
      name: 'Commit repository updates',
      uses: Tools.stefanzweifelGitAutoCommitAction,
      withArgs: {
        'branch': _gpPagesBranch,
        'repository': 'repo',
        'skip_dirty_check': true,
      },
    ),
  ];
}
