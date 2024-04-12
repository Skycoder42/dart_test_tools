import 'dart:io';

import '../tools/github.dart';
import 'repo_metadata.dart';

class RepoGenerator {
  const RepoGenerator();

  Future<void> call({
    required Directory repo,
    required RepoMetadata metadata,
    bool update = false,
  }) async {
    if (!update) {
      await _initRepo(repo);
    }

    await _updateRepo(repo, metadata);
  }

  Future<void> _initRepo(Directory repo) => Github.exec('ostree', [
        'init',
        '--mode=archive',
        '--repo=${repo.path}',
      ]);

  Future<void> _updateRepo(
    Directory repo,
    RepoMetadata metadata,
  ) =>
      Github.exec('flatpak', [
        'build-update-repo',
        if (metadata.title case String title) '--title=$title',
        if (metadata.summary case String summary) '--comment=$summary',
        if (metadata.description case String description)
          '--description=$description',
        if (metadata.homepage case Uri homepage) '--homepage=$homepage',
        if (metadata.icon case IconInfo(iconUrl: final iconUrl))
          '--icon=$iconUrl',
        '--gpg-import=${metadata.gpgInfo.publicKeyFile.path}',
        '--default-branch=${metadata.branch}',
        '--generate-static-deltas',
        '--prune',
        '--gpg-sign=${metadata.gpgInfo.keyId}',
        repo.path,
      ]);
}
