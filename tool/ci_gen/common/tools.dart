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

  // Keys are the action spec strings read by tool/ci_update_actions.dart.
  static final toolSpecs = <String, void Function(String)>{
    'actions/checkout@v7': (t) => actionsCheckout = t,
    'actions/upload-artifact@v7': (t) => actionsUploadArtifact = t,
    'actions/download-artifact@v8': (t) => actionsDownloadArtifact = t,
    'actions/cache@v5': (t) => actionsCache = t,
    'actions/setup-java@v5': (t) => actionsSetupJava = t,
    'dart-lang/setup-dart@v1': (t) => dartLangSetupDart = t,
    'docker/setup-qemu-action@v4': (t) => dockerSetupQemuAction = t,
    'docker/setup-buildx-action@v4': (t) => dockerSetupBuildxAction = t,
    'docker/login-action@v4': (t) => dockerLoginAction = t,
    'docker/build-push-action@v7': (t) => dockerBuildAndPushAction = t,
    'subosito/flutter-action@v2': (t) => subositoFlutterAction = t,
    'softprops/action-gh-release@v3': (t) => softpropsActionGhRelease = t,
    'VeryGoodOpenSource/very_good_coverage@v3': (t) =>
        veryGoodOpenSourceVeryGoodCoverage = t,
    'lpenz/ghaction-packagecloud@v0.6.0': (t) => lpenzGhactionPackagecloud = t,
    'flatpak/flatpak-github-actions/flatpak-builder@v6': (t) =>
        flatpakFlatpakGithubActionsFlatpakBuilder = t,
    'stefanzweifel/git-auto-commit-action@v7': (t) =>
        stefanzweifelGitAutoCommitAction = t,
    'actions/setup-node@v6': (t) => actionsSetupNode = t,
    'microsoft/setup-msstore-cli@v1': (t) => microsoftSetupMsstoreCli = t,
    'apple-actions/import-codesign-certs@v7': (t) =>
        appleActionsImportCodesignCerts = t,
    'google-github-actions/auth@v3': (t) => googleGithubActionsAuth = t,
    'google-github-actions/setup-gcloud@v3': (t) =>
        googleGithubActionsSetupGcloud = t,
    'peter-evans/create-pull-request@v8': (t) =>
        peterEvansCreatePullRequest = t,
    'thollander/actions-comment-pull-request@v3': (t) =>
        thollanderActionsCommentPullRequest = t,
    'benc-uk/workflow-dispatch@v1': (t) => bencUkWorkflowDispatch = t,
  };

  static Future<void> setup() => Future.wait([
    for (final entry in toolSpecs.entries)
      _resolve(entry.key).then(entry.value),
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
