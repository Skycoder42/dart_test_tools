import 'dart:io';

import 'github.dart';

abstract base class Archive {
  static final _tarFileRegexp = RegExp(r'.*\.tar(?:\.\w+)?$');

  Archive._();

  static Future<void> extract({
    required File archive,
    required Directory outDir,
  }) async {
    if (_tarFileRegexp.hasMatch(archive.path)) {
      await Github.exec('tar', [
        '-xvf',
        archive.path,
      ], workingDirectory: outDir);
    } else {
      await Github.exec('7z', ['x', '-y', '-o${outDir.path}', archive.path]);
    }
  }

  static Future<void> compress({
    required Directory inDir,
    required File archive,
  }) async {
    if (_tarFileRegexp.hasMatch(archive.path)) {
      await Github.exec('tar', [
        '-cavf',
        archive.path,
        '.',
      ], workingDirectory: inDir);
    } else {
      await Github.exec('7z', [
        'a',
        '-y',
        archive.path,
        '.',
      ], workingDirectory: inDir);
    }
  }
}
