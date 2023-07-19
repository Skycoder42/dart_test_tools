import 'dart:io';

import 'package:dart_test_tools/src/tools/io.dart';
import 'package:path/path.dart';
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
        join(Directory.systemTemp.path, 'test'),
      );
    });

    test('subFile returns subfile', () {
      expect(
        Directory.systemTemp.subFile('test').path,
        join(Directory.systemTemp.path, 'test'),
      );
    });
  });

  group('HttpClientX', () {
    test('download downloads file with signature', () {
      // TODO implement test
      fail("TODO implement test");
    });
  });
}
