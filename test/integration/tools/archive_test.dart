import 'dart:io';

import 'package:dart_test_tools/src/tools/archive.dart';
import 'package:dart_test_tools/src/tools/io.dart';
import 'package:test/test.dart';

void main() {
  group('$Archive', () {
    void _testArchive(String suffix, {String? testOn}) {
      test(
        'can create and extract $suffix archives',
        testOn: testOn,
        () async {
          final tmpDir = await Directory.systemTemp.createTemp();
          addTearDown(() => tmpDir.delete(recursive: true));

          final inDir = await tmpDir.subDir('in').create();
          final outDir = await tmpDir.subDir('out').create();
          await inDir.subFile('test.txt').writeAsString('test');

          final archive = tmpDir.subFile('test.$suffix');
          await Archive.compress(inDir: inDir, archive: archive);
          await Archive.extract(archive: archive, outDir: outDir);

          expect(outDir.list().toList(), completion(hasLength(1)));
          final outFile = outDir.subFile('test.txt');
          expect(outFile.existsSync(), isTrue);
          expect(outFile.readAsString(), completion('test'));
        },
      );
    }

    _testArchive('tar.xz', testOn: 'posix');

    _testArchive('zip');
  });
}
