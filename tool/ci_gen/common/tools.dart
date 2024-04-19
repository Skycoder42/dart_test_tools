abstract class Tools {
  Tools._();

  /// https://github.com/actions/checkout/releases
  static const actionsCheckout = 'actions/checkout@v4';

  /// https://github.com/actions/upload-artifact/releases
  static const actionsUploadArtifact = 'actions/upload-artifact@v4';

  /// https://github.com/actions/download-artifact/releases
  static const actionsDownloadArtifact = 'actions/download-artifact@v4';

  /// https://github.com/actions/cache/releases
  static const actionsCache = 'actions/cache@v4';

  /// https://github.com/actions/setup-java/releases
  static const actionsSetupJava = 'actions/setup-java@v4';

  /// https://github.com/dart-lang/setup-dart/releases
  static const dartLangSetupDart = 'dart-lang/setup-dart@v1';

  /// https://github.com/docker/setup-qemu-action/releases
  static const dockerSetupQemuAction = 'docker/setup-qemu-action@v3';

  /// https://github.com/docker/setup-buildx-action/releases
  static const dockerSetupBuildxAction = 'docker/setup-buildx-action@v3';

  /// https://github.com/docker/login-action/releases
  static const dockerLoginAction = 'docker/login-action@v3';

  /// https://github.com/docker/build-push-action/releases
  static const dockerBuildAndPushAction = 'docker/build-push-action@v5';

  /// https://github.com/subosito/flutter-action/releases
  static const subositoFlutterAction = 'subosito/flutter-action@v2';

  /// https://github.com/softprops/action-gh-release/releases
  static const softpropsActionGhRelease = 'softprops/action-gh-release@v2';

  /// https://github.com/VeryGoodOpenSource/very_good_coverage/releases
  static const veryGoodOpenSourceVeryGoodCoverage =
      'VeryGoodOpenSource/very_good_coverage@v3';

  /// https://github.com/lpenz/ghaction-packagecloud/releases
  static const lpenzGhactionPackagecloud = 'lpenz/ghaction-packagecloud@v0.4';

  /// https://github.com/bilelmoussaoui/flatpak-github-actions/releases
  static const bilelmoussaouiFlatpakGithubActionsFlatpakBuilder =
      'bilelmoussaoui/flatpak-github-actions/flatpak-builder@86f5f35aa999f626a05d2943460ff0e811655327';
  // TODO change back to v6 once upload-artifact option has been published

  /// https://github.com/stefanzweifel/git-auto-commit-action/releases
  static const stefanzweifelGitAutoCommitAction =
      'stefanzweifel/git-auto-commit-action@v5';

  /// https://github.com/actions/setup-node/releases
  static const actionsSetupNode = 'actions/setup-node@v4';
}
