import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../tools/io.dart';
import 'repo_metadata.dart';

class RepoFileGenerator {
  static final _whitespaceRegex = RegExp(r'\s+');

  const RepoFileGenerator();

  Future<void> call({
    required Directory repo,
    required RepoMetadata metadata,
  }) async {
    final gpgKey = await _loadGpgKey(metadata);

    final repoInfo = _createRepInfo(metadata, gpgKey);
    await _writeInfoFile(
      repo.subFile(path.setExtension(metadata.name, '.flatpakrepo')),
      'Flatpak Repo',
      repoInfo,
    );

    final refInfo = _createRefInfo(metadata, gpgKey);
    await _writeInfoFile(
      repo.subFile(path.setExtension(metadata.name, '.flatpakref')),
      'Flatpak Ref',
      refInfo,
    );

    await _copyIcon(repo, metadata);
  }

  Future<String> _loadGpgKey(RepoMetadata metadata) =>
      metadata.gpgInfo.publicKeyFile
          .openRead()
          .transform(base64.encoder)
          .join();

  Map<String, String> _createRepInfo(RepoMetadata metadata, String gpgKey) => {
    'Url': metadata.url.toString(),
    'Title': '${metadata.title ?? metadata.name} Repository',
    ..._createCommonInfo(metadata, gpgKey),
  };

  Map<String, String> _createRefInfo(RepoMetadata metadata, String gpgKey) => {
    'Name': metadata.id,
    'Url': metadata.url.toString(),
    'Branch': metadata.branch,
    'RuntimeRepo': 'https://dl.flathub.org/repo/flathub.flatpakrepo',
    'IsRuntime': 'false',
    'Title': metadata.title ?? metadata.name,
    ..._createCommonInfo(metadata, gpgKey),
  };

  Map<String, String> _createCommonInfo(RepoMetadata metadata, String gpgKey) =>
      {
        if (metadata.homepage case final Uri homepage)
          'Homepage': homepage.toString(),
        if (metadata.summary case final String summary) 'Comment': summary,
        if (metadata.description case final String description)
          'Description': description.replaceAll(_whitespaceRegex, ' ').trim(),
        if (metadata.icon case IconInfo(iconUrl: final iconUrl))
          'Icon': iconUrl.toString(),
        'GPGKey': gpgKey,
      };

  Future<void> _writeInfoFile(
    File file,
    String descriptor,
    Map<String, String> repoInfo,
  ) async {
    final sink = file.openWrite();
    try {
      sink.writeln('[$descriptor]');
      for (final entry in repoInfo.entries) {
        sink
          ..write(entry.key)
          ..write('=')
          ..writeln(entry.value);
      }
    } finally {
      await sink.close();
    }
  }

  Future<void> _copyIcon(Directory repo, RepoMetadata metadata) async {
    if (metadata.icon case IconInfo(
      iconName: final iconName,
      iconFile: final iconFile,
    )) {
      await iconFile.copy(repo.subFile(iconName).path);
    }
  }
}
