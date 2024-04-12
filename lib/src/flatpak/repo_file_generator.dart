import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../tools/io.dart';
import 'repo_metadata.dart';

class RepoFileGenerator {
  static final _whitespaceRegex = RegExp(r'\s+');

  const RepoFileGenerator();

  Future<void> call({
    required Directory repo,
    required RepoMetadata metadata,
  }) async {
    final repoInfo = await _createRepInfo(metadata);

    final flatpakRepoFileSink = repo
        .subFile(path.setExtension(metadata.name, '.flatpakrepo'))
        .openWrite();
    try {
      _writeRepoInfo(flatpakRepoFileSink, repoInfo);
    } finally {
      await flatpakRepoFileSink.close();
    }

    await _copyIcon(repo, metadata);
  }

  Future<Map<String, String>> _createRepInfo(RepoMetadata metadata) async => {
        'Title': '${metadata.title ?? metadata.name} Repository',
        'Url': metadata.url.toString(),
        if (metadata.homepage case Uri homepage)
          'Homepage': homepage.toString(),
        if (metadata.summary case String summary) 'Comment': summary,
        if (metadata.description case String description)
          'Description': description.replaceAll(_whitespaceRegex, ' ').trim(),
        if (metadata.icon case IconInfo(iconUrl: final iconUrl))
          'Icon': iconUrl.toString(),
        'GPGKey': await metadata.gpgInfo.publicKeyFile
            .openRead()
            .transform(base64.encoder)
            .join(),
      };

  void _writeRepoInfo(
    StringSink sink,
    Map<String, String> repoInfo,
  ) {
    sink.writeln('[Flatpak Repo]');
    for (final entry in repoInfo.entries) {
      sink
        ..write(entry.key)
        ..write('=')
        ..writeln(entry.value);
    }
  }

  Future<void> _copyIcon(Directory repo, RepoMetadata metadata) async {
    if (metadata.icon
        case IconInfo(iconName: final iconName, iconFile: final iconFile)) {
      await iconFile.copy(repo.subFile(iconName).path);
    }
  }
}
