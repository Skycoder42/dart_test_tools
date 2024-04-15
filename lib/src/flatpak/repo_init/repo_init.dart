import 'dart:io';

import 'metadata_collector.dart';
import 'repo_file_generator.dart';
import 'repo_generator.dart';

class RepoInit {
  final MetadataCollector _metadataCollector;
  final RepoGenerator _repoGenerator;
  final RepoFileGenerator _repoFileGenerator;

  const RepoInit([
    this._metadataCollector = const MetadataCollector(),
    this._repoGenerator = const RepoGenerator(),
    this._repoFileGenerator = const RepoFileGenerator(),
  ]);

  Future<void> call({
    required Directory repo,
    required File metaInfo,
    required String gpgKeyId,
    File? icon,
    bool update = false,
  }) async {
    final metadata = await _metadataCollector(
      repo: repo,
      metaInfo: metaInfo,
      gpgKeyId: gpgKeyId,
      icon: icon,
    );

    await _repoGenerator(
      repo: repo,
      metadata: metadata,
      update: update,
    );

    await _repoFileGenerator(
      repo: repo,
      metadata: metadata,
    );
  }
}
