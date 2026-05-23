import 'package:dart_test_tools/src/tools/github.dart';

abstract class Tools {
  Tools._();

  /// https://github.com/actions/checkout/releases
  static late final String actionsCheckout;

  /// https://github.com/actions/upload-artifact/releases
  static late final String actionsUploadArtifact;

  /// https://github.com/actions/download-artifact/releases
  static late final String actionsDownloadArtifact;

  /// https://github.com/actions/cache/releases
  static late final String actionsCache;

  /// https://github.com/actions/setup-java/releases
  static late final String actionsSetupJava;

  /// https://github.com/dart-lang/setup-dart/releases
  static late final String dartLangSetupDart;

  /// https://github.com/docker/setup-qemu-action/releases
  static late final String dockerSetupQemuAction;

  /// https://github.com/docker/setup-buildx-action/releases
  static late final String dockerSetupBuildxAction;

  /// https://github.com/docker/login-action/releases
  static late final String dockerLoginAction;

  /// https://github.com/docker/build-push-action/releases
  static late final String dockerBuildAndPushAction;

  /// https://github.com/subosito/flutter-action/releases
  static late final String subositoFlutterAction;

  /// https://github.com/softprops/action-gh-release/releases
  static late final String softpropsActionGhRelease;

  /// https://github.com/VeryGoodOpenSource/very_good_coverage/releases
  static late final String veryGoodOpenSourceVeryGoodCoverage;

  /// https://github.com/lpenz/ghaction-packagecloud/releases
  static late final String lpenzGhactionPackagecloud;

  /// https://github.com/flatpak/flatpak-github-actions/releases
  static late final String flatpakFlatpakGithubActionsFlatpakBuilder;

  /// https://github.com/stefanzweifel/git-auto-commit-action/releases
  static late final String stefanzweifelGitAutoCommitAction;

  /// https://github.com/actions/setup-node/releases
  static late final String actionsSetupNode;

  /// https://github.com/microsoft/setup-msstore-cli/releases
  static late final String microsoftSetupMsstoreCli;

  /// https://github.com/apple-actions/import-codesign-certs/releases
  static late final String appleActionsImportCodesignCerts;

  /// https://github.com/google-github-actions/auth/releases
  static late final String googleGithubActionsAuth;

  /// https://github.com/google-github-actions/setup-gcloud/releases
  static late final String googleGithubActionsSetupGcloud;

  /// https://github.com/peter-evans/create-pull-request/releases
  static late final String peterEvansCreatePullRequest;

  /// https://github.com/thollander/actions-comment-pull-request/releases
  static late final String thollanderActionsCommentPullRequest;

  /// https://github.com/benc-uk/workflow-dispatch/releases
  static late final String bencUkWorkflowDispatch;

  static Future<void> setup() => Future.wait([
        _resolve('actions/checkout@v6').then((v) => actionsCheckout = v),
        _resolve('actions/upload-artifact@v7')
            .then((v) => actionsUploadArtifact = v),
        _resolve('actions/download-artifact@v8')
            .then((v) => actionsDownloadArtifact = v),
        _resolve('actions/cache@v5').then((v) => actionsCache = v),
        _resolve('actions/setup-java@v5').then((v) => actionsSetupJava = v),
        _resolve('dart-lang/setup-dart@v1').then((v) => dartLangSetupDart = v),
        _resolve('docker/setup-qemu-action@v4')
            .then((v) => dockerSetupQemuAction = v),
        _resolve('docker/setup-buildx-action@v4')
            .then((v) => dockerSetupBuildxAction = v),
        _resolve('docker/login-action@v4').then((v) => dockerLoginAction = v),
        _resolve('docker/build-push-action@v7')
            .then((v) => dockerBuildAndPushAction = v),
        _resolve('subosito/flutter-action@v2')
            .then((v) => subositoFlutterAction = v),
        _resolve('softprops/action-gh-release@v3')
            .then((v) => softpropsActionGhRelease = v),
        _resolve('VeryGoodOpenSource/very_good_coverage@v3')
            .then((v) => veryGoodOpenSourceVeryGoodCoverage = v),
        _resolve('lpenz/ghaction-packagecloud@v0.5')
            .then((v) => lpenzGhactionPackagecloud = v),
        _resolve('flatpak/flatpak-github-actions/flatpak-builder@v6')
            .then((v) => flatpakFlatpakGithubActionsFlatpakBuilder = v),
        _resolve('stefanzweifel/git-auto-commit-action@v7')
            .then((v) => stefanzweifelGitAutoCommitAction = v),
        _resolve('actions/setup-node@v6').then((v) => actionsSetupNode = v),
        _resolve('microsoft/setup-msstore-cli@v1')
            .then((v) => microsoftSetupMsstoreCli = v),
        _resolve('apple-actions/import-codesign-certs@v7')
            .then((v) => appleActionsImportCodesignCerts = v),
        _resolve('google-github-actions/auth@v3')
            .then((v) => googleGithubActionsAuth = v),
        _resolve('google-github-actions/setup-gcloud@v3')
            .then((v) => googleGithubActionsSetupGcloud = v),
        _resolve('peter-evans/create-pull-request@v8')
            .then((v) => peterEvansCreatePullRequest = v),
        _resolve('thollander/actions-comment-pull-request@v3')
            .then((v) => thollanderActionsCommentPullRequest = v),
        _resolve('benc-uk/workflow-dispatch@v1.3.2')
            .then((v) => bencUkWorkflowDispatch = v),
      ]);

  static Future<String> _resolve(String tool) async {
    final atIndex = tool.lastIndexOf('@');
    final ref = tool.substring(atIndex + 1);
    final actionPath = tool.substring(0, atIndex);
    final repoParts = actionPath.split('/');
    final repo = '${repoParts[0]}/${repoParts[1]}';

    final lines = await Github.execLines('git', [
      'ls-remote',
      'https://github.com/$repo.git',
      'refs/tags/$ref',
      'refs/tags/$ref^{}',
    ]).toList();

    final line = lines.lastWhere(
      (l) => l.contains('^{}'),
      orElse: () => lines.first,
    );
    return '$actionPath@${line.split('\t').first}';
  }
}
