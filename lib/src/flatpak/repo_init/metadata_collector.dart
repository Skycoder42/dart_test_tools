import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

import '../../tools/github.dart';
import '../../tools/io.dart';
import 'repo_metadata.dart';

class MetadataCollector {
  const MetadataCollector();

  Future<RepoMetadata> call({
    required Directory repo,
    required File metaInfo,
    required String gpgKeyId,
    required File? icon,
  }) async {
    final (username, repository) = await _loadRepoInfo(repo);
    final defaultBranch = await _loadDefaultBranch(repo);
    final publicKeyFile = await _exportGpgKey(gpgKeyId);

    var metadata = RepoMetadata(
      name: repository,
      id: 'PLACEHOLDER',
      url: Uri.https('${username.toLowerCase()}.github.io', '/$repository/'),
      gpgInfo: GpgInfo(keyId: gpgKeyId, publicKeyFile: publicKeyFile),
      branch: defaultBranch,
    );

    metadata = await _addMetaInfo(metadata, metaInfo);

    if (icon != null) {
      metadata = _addIconInfo(metadata, icon);
    }

    return metadata;
  }

  Future<(String, String)> _loadRepoInfo(Directory repo) async {
    final remoteString = await Github.execLines('git', const [
      'config',
      '--get',
      'remote.origin.url',
    ], workingDirectory: repo).single;
    final remoteUrl = Uri.parse(remoteString);

    if (remoteUrl.origin != 'https://github.com') {
      throw Exception('Can only work with GitHub HTTPS remotes');
    }

    final [username, repository, ...] = remoteUrl.pathSegments;
    return (username, path.withoutExtension(repository));
  }

  Future<String> _loadDefaultBranch(Directory repo) async {
    final defaultRef = await Github.execLines('git', const [
      'symbolic-ref',
      'refs/remotes/origin/HEAD',
      '--short',
    ], workingDirectory: repo).single;
    return defaultRef.split('/').last;
  }

  Future<File> _exportGpgKey(String gpgKeyId) async {
    final tmpDir = await Directory.systemTemp.createTemp();
    final gpgFile = tmpDir.subFile('$gpgKeyId.key');
    await Github.exec('gpg', [
      '--batch',
      '--yes',
      '--export',
      '--armor',
      '-o',
      gpgFile.path,
      gpgKeyId,
    ]);
    return gpgFile;
  }

  Future<RepoMetadata> _addMetaInfo(
    RepoMetadata metadata,
    File metaInfo,
  ) async {
    final metaInfoString = await metaInfo.readAsString();
    final metaInfoXml = XmlDocument.parse(metaInfoString);

    final homepageUrl = metaInfoXml
        .xpath('/component/url[@type = "homepage"]')
        .firstOrNull
        ?.innerText;

    return metadata.copyWith(
      id: metaInfoXml.xpath('/component/id').first.innerText,
      title: metaInfoXml.xpath('/component/name').firstOrNull?.innerText,
      summary: metaInfoXml.xpath('/component/summary').firstOrNull?.innerText,
      description: metaInfoXml
          .xpath('/component/description')
          .firstOrNull
          ?.innerText,
      homepage: homepageUrl != null ? Uri.parse(homepageUrl) : null,
    );
  }

  RepoMetadata _addIconInfo(RepoMetadata metadata, File icon) {
    final iconName = 'icon${path.extension(icon.path)}';
    return metadata.copyWith(
      icon: IconInfo(
        iconName: iconName,
        iconUrl: metadata.url.resolve(iconName),
        iconFile: icon,
      ),
    );
  }
}
