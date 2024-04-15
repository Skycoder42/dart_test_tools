import 'dart:async';
import 'dart:io';

extension FileSystemEntityX on FileSystemEntity {
  void assertExists() {
    if (!existsSync()) {
      throw Exception('$this does not exists');
    }
  }
}

extension DirectoryX on Directory {
  Directory subDir(String path) => Directory.fromUri(uri.resolve(path));

  File subFile(String path) => File.fromUri(uri.resolve(path));
}

extension HttpClientX on HttpClient {
  Future<File> download(
    Directory targetDir,
    Uri uri, {
    bool withSignature = true,
  }) async {
    final request = await getUrl(uri);
    final response = await request.close();
    if (response.statusCode >= 300) {
      throw Exception(
        'Request failed with status code: ${response.statusCode}',
      );
    }

    final outFile = targetDir.subFile(uri.pathSegments.last);
    await response.pipe(outFile.openWrite());

    if (withSignature) {
      await download(
        targetDir,
        uri.replace(path: '${uri.path}.minisig'),
        withSignature: false,
      );
    }

    return outFile;
  }

  Future<String> getHeader(Uri url, String headerName) async {
    final request = await headUrl(url);
    final response = await request.close();
    response.drain<void>().ignore();
    if (response.statusCode >= 300) {
      throw Exception(
        'Request failed with status code: ${response.statusCode}',
      );
    }

    final header = response.headers[headerName];
    if (header == null || header.isEmpty) {
      throw Exception(
        'Unable to get header $header from $url: Header is not set',
      );
    }

    return header.first;
  }
}
