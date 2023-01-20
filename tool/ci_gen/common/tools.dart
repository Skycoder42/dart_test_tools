abstract class Tools {
  Tools._();

  /// https://github.com/actions/checkout/releases
  static const actionsCheckout = 'actions/checkout@v3';

  /// https://github.com/actions/upload-artifact/releases
  static const actionsUploadArtifact = 'actions/upload-artifact@v3';

  /// https://github.com/actions/download-artifact/releases
  static const actionsDownloadArtifact = 'actions/download-artifact@v3';

  /// https://github.com/actions/cache/releases
  static const actionsCache = 'actions/cache@v3';

  /// https://github.com/actions/setup-java/releases
  static const actionsSetupJava = 'actions/setup-java@v3';

  /// https://github.com/dart-lang/setup-dart/releases
  static const dartLangSetupDart = 'dart-lang/setup-dart@v1';

  /// https://github.com/docker/setup-qemu-action/releases
  static const dockerSetupQemuAction = 'docker/setup-qemu-action@v2';

  /// https://github.com/docker/setup-buildx-action/releases
  static const dockerSetupBuildxAction = 'docker/setup-buildx-action@v2';

  /// https://github.com/docker/login-action/releases
  static const dockerLoginAction = 'docker/login-action@v2';

  /// https://github.com/docker/build-push-action/releases
  static const dockerBuildAndPushAction = 'docker/build-push-action@v3';

  /// https://github.com/subosito/flutter-action/releases
  static const subositoFlutterAction = 'subosito/flutter-action@v2';

  /// https://github.com/softprops/action-gh-release/releases
  static const softpropsActionGhRelease = 'softprops/action-gh-release@v1';

  /// https://github.com/VeryGoodOpenSource/very_good_coverage/releases
  static const veryGoodOpenSourceVeryGoodCoverage =
      'VeryGoodOpenSource/very_good_coverage@v2';

  /// https://github.com/peter-evans/repository-dispatch/releases
  static const peterEvansRepositoryDispatch =
      'peter-evans/repository-dispatch@v2';
}
