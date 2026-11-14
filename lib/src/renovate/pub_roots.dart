import 'dart:io';

import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

@internal
class PubRoots(final Directory repoRoot) {
  static const root = '.';

  Pubspec? _repoRootPubspec;

  Future<String> findRoot(String packageFile) async {
    final packageDir = path.posix.normalize(path.posix.dirname(packageFile));
    final pubspec = await _readPubspec(packageDir);
    if (pubspec.resolution != 'workspace') {
      return packageDir;
    }

    final workspace = (await _readRootPubspec()).workspace ?? const [];
    final isMember = workspace.any(
      (entry) => Glob(path.posix.normalize(entry)).matches(packageDir),
    );
    if (!isMember) {
      throw StateError(
        'Workspace member $packageDir is not listed in the workspace of the '
        'repository root pubspec.yaml',
      );
    }

    return root;
  }

  Future<Pubspec> _readRootPubspec() async =>
      _repoRootPubspec ??= await _readPubspec(root);

  Future<Pubspec> _readPubspec(String packageDir) async {
    final pubspecFile = File(
      path.join(repoRoot.path, packageDir, 'pubspec.yaml'),
    );
    return Pubspec.parse(
      await pubspecFile.readAsString(),
      sourceUrl: pubspecFile.uri,
    );
  }
}
