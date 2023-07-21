import 'dart:io';

import 'package:dart_test_tools/src/tools/github.dart';

abstract base class Minisign {
  static bool _forceDocker = false;

  Minisign._();

  static bool get _useDocker =>
      _forceDocker || Platform.environment['MINISIGN_DOCKER'] == 'true';

  static Future<void> ensureInstalled() async {
    // check if minisign is already installed
    try {
      if (_useDocker) {
        return;
      }

      await Github.exec('minisign', const ['-v']);
      return;
    } on ProcessException catch (e) {
      Github.logDebug(e.toString());
    }

    // if not, install it
    if (Platform.isLinux) {
      _forceDocker = true;
      await Github.exec('docker', const ['pull', 'jedisct1/minisign']);
    } else if (Platform.isMacOS) {
      await Github.exec('brew', const ['install', 'minisign']);
    } else if (Platform.isWindows) {
      await Github.exec(
        'scoop',
        const ['install', 'minisign'],
        runInShell: true,
      );
    } else {
      throw Exception('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  static Future<void> verify(
    File file,
    String publicKey,
  ) async {
    if (_useDocker) {
      final filename = file.uri.pathSegments.last;
      await Github.exec('docker', [
        'run',
        '--rm',
        '-v',
        '${file.parent.path}:/src:ro',
        'jedisct1/minisign',
        '-P',
        publicKey,
        '-Vm',
        '/src/$filename',
      ]);
    } else {
      await Github.exec('minisign', [
        '-P',
        publicKey,
        '-Vm',
        file.path,
      ]);
    }
  }

  static Future<void> sign(File file, File secretKey) async {
    if (_useDocker) {
      final filename = file.uri.pathSegments.last;
      await Github.exec('docker', [
        'run',
        '--rm',
        '-v',
        '${file.parent.path}:/src',
        '-v',
        '${secretKey.path}:/run/secrets/minisign.key:ro',
        'jedisct1/minisign',
        '-Ss',
        '/run/secrets/minisign.key',
        '-m',
        '/src/$filename',
      ]);
    } else {
      await Github.exec('minisign', [
        '-Ss',
        secretKey.path,
        '-m',
        file.path,
      ]);
    }
  }
}
