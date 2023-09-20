@TestOn('dart-vm')
library io_test;

import 'dart:io';

import 'package:dart_test_tools/src/tools/io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('FileSystemEntityX', () {
    test('assertExists throws exception if FSE does not exist', () {
      final testFile =
          Directory.systemTemp.subFile('file-that-should-not-exist');
      expect(
        () => testFile.assertExists(),
        throwsA(isException.having(
          (m) => m.toString(),
          'toString()',
          contains(testFile.toString()),
        )),
      );
    });
  });

  group('DirectoryX', () {
    test('subDir returns subdirectory', () {
      expect(
        Directory.systemTemp.subDir('test').path,
        path.join(Directory.systemTemp.path, 'test'),
      );
    });

    test('subFile returns subfile', () {
      expect(
        Directory.systemTemp.subFile('test').path,
        path.join(Directory.systemTemp.path, 'test'),
      );
    });
  });

  group('HttpClientX', () {
    test('download downloads file with signature', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(request.requestedUri.toString());
        request.response.close();
      });

      final uri = Uri.http(
        '${server.address.address}:${server.port}',
        '/test/download/uri',
      );

      final client = HttpClient();
      addTearDown(client.close);

      final tmpDir = await Directory.systemTemp.createTemp();
      addTearDown(() => tmpDir.delete(recursive: true));

      final file = await client.download(tmpDir, uri);
      expect(tmpDir.list().toList(), completion(hasLength(2)));

      expect(file.existsSync(), isTrue);
      expect(path.equals(file.parent.path, tmpDir.path), isTrue);
      expect(file.readAsString(), completion(uri.toString()));

      final sigFile = File('${file.path}.minisig');
      expect(sigFile.existsSync(), isTrue);
      expect(path.equals(sigFile.parent.path, tmpDir.path), isTrue);
      expect(sigFile.readAsString(), completion('$uri.minisig'));
    });

    group('getHeader', () {
      test('returns header value if present', () async {
        const headerName = "Test-Header";
        const headerValue = "test-header-value";

        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        server.listen((request) {
          request.response.statusCode = request.method == "HEAD"
              ? HttpStatus.ok
              : HttpStatus.methodNotAllowed;
          request.response.headers.add(headerName, headerValue);
          request.response.close();
        });

        final uri = Uri.http('${server.address.address}:${server.port}', '/');

        final client = HttpClient();
        addTearDown(client.close);

        final result = await client.getHeader(uri, headerName);

        expect(result, headerValue);
      });

      test('throws if header is not present', () async {
        const headerName = "Test-Header";

        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        server.listen((request) {
          request.response.statusCode = request.method == "HEAD"
              ? HttpStatus.ok
              : HttpStatus.methodNotAllowed;
          request.response.close();
        });

        final uri = Uri.http('${server.address.address}:${server.port}', '/');

        final client = HttpClient();
        addTearDown(client.close);

        expect(
          () => client.getHeader(uri, headerName),
          throwsException,
        );
      });
    });
  });
}
