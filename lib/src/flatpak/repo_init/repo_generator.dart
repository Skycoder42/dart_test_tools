import 'dart:io';

import '../../tools/github.dart';
import '../../tools/io.dart';
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

  Future<void> _initRepo(Directory repo) async {
    await Github.exec('ostree', [
      'init',
      '--mode=archive',
      '--repo=${repo.path}',
    ]);

    final emptyDirs = await repo
        .list(recursive: true)
        .where((e) => e is Directory)
        .cast<Directory>()
        .asyncMap((d) async => (d, await d.list().isEmpty))
        .where((d) => d.$2)
        .map((d) => d.$1)
        .toList();
    for (final dir in emptyDirs) {
      await dir.subFile('.gitkeep').create();
    }
  }

  Future<void> _updateRepo(Directory repo, RepoMetadata metadata) =>
      Github.exec('flatpak', [
        'build-update-repo',
        if (metadata.title case final String title) '--title=$title',
        if (metadata.summary case final String summary) '--comment=$summary',
        if (metadata.description case final String description)
          '--description=$description',
        if (metadata.homepage case final Uri homepage) '--homepage=$homepage',
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
