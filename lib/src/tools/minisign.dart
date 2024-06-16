import 'dart:io';

import 'archive.dart';
import 'github.dart';
import 'io.dart';

abstract base class Minisign {
  static bool _forceDocker = false;
  static bool _forceKnownPath = false;

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
      _forceKnownPath = true;
      final client = HttpClient();
      final minisignZip = await client.download(
        Github.env.runnerTemp,
        Uri.parse(
          'https://github.com/jedisct1/minisign/releases/download/0.11/minisign-win64.zip',
        ),
        withSignature: false,
      );
      await Archive.extract(
        archive: minisignZip,
        outDir: Github.env.runnerToolCache,
      );

      await Github.env.addPath(
        Github.env.runnerToolCache.subDir('minisign-win64'),
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
      await Github.exec(_minisignExecutable, [
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
      await Github.exec(_minisignExecutable, [
        '-Ss',
        secretKey.path,
        '-m',
        file.path,
      ]);
    }
  }

  static String get _minisignExecutable => _forceKnownPath
      ? Github.env.runnerToolCache
          .subDir('minisign-win64')
          .subFile('minisign.exe')
          .path
      : 'minisign';
}
