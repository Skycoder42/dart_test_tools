@TestOn('dart-vm')
library minisign_test;

import 'dart:io';

import 'package:dart_test_tools/src/tools/io.dart';
import 'package:dart_test_tools/src/tools/minisign.dart';
import 'package:test/test.dart';

void main() {
  group('$Minisign', onPlatform: {
    'windows': const Skip('Scoop minisign is broken'),
  }, () {
    test('installs minisign', () async {
      printOnFailure(
        Platform.environment.entries
            .map((e) => '${e.key}=${e.value}')
            .join('\n'),
      );

      await Minisign.ensureInstalled();

      expect(
        _runMinisign(Directory.systemTemp, const ['-v']),
        completion(0),
      );
    });

    test('can create and verify a signature', () async {
      final tmpDir = await Directory.systemTemp.createTemp();
      addTearDown(() => tmpDir.delete(recursive: true));

      final testFile = tmpDir.subFile('test-file.txt');
      await testFile.writeAsString('This is some test content');

      await expectLater(
        _runMinisign(tmpDir, const [
          '-GW',
          '-p',
          'minisign-key.pub',
          '-s',
          'minisign-key.sec',
        ]),
        completion(0),
      );

      await Minisign.sign(testFile, tmpDir.subFile('minisign-key.sec'));

      final pubKey = await tmpDir.subFile('minisign-key.pub').readAsLines();
      await Minisign.verify(testFile, pubKey.last.trim());
    });
  });
}

Future<int> _runMinisign(Directory testDir, List<String> arguments) async {
  final String executable;
  final List<String> fullArgs;
  if (Platform.isLinux) {
    executable = 'docker';
    fullArgs = [
      'run',
      '--rm',
      '-v',
      '${testDir.path}:/data',
      '-w',
      '/data',
      'jedisct1/minisign',
      ...arguments,
    ];
  } else {
    executable = 'minisign';
    fullArgs = arguments;
  }

  final result = await Process.start(
    executable,
    fullArgs,
    workingDirectory: testDir.path,
    mode: ProcessStartMode.inheritStdio,
  );
  return result.exitCode;
}
