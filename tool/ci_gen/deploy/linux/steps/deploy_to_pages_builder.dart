import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/tools.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';
import 'with_gpg_key.dart';

base mixin DeployToPagesConfig on JobConfig, WithGpgKeyConfig {
  @override
  bool get requireGpgKey => false;
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
    const Step.uses(
      name: 'Download flatpak bundle artifacts',
      uses: Tools.actionsDownloadArtifact,
      withArgs: {'pattern': 'flatpak-bundle-*', 'path': 'bundles'},
    ),
    ...WithGpgKey(
      config: config,
      steps: [
        Step.run(
          name: 'Import bundles into repository',
          run: '''
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
    const Step.uses(
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
