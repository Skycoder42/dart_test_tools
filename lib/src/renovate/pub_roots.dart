import 'dart:io';

import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';

@internal
class PubRoots(final Directory repoRoot) {
  Future<List<Directory>> resolve(Iterable<String> packageFiles) async {
    final roots = <String>{};
    for (final packageFile in packageFiles) {
      roots.add(await _findRoot(packageFile));
    }
    return roots
        .map(
          (root) => Directory(path.normalize(path.join(repoRoot.path, root))),
        )
        .toList();
  }

  Future<String> _findRoot(String packageFile) async {
    final packageDir = path.posix.normalize(path.posix.dirname(packageFile));
    final pubspec = await _readPubspec(packageDir);
    if (pubspec.resolution != 'workspace') {
      return packageDir;
    }

    final workspace = (await _readPubspec('.')).workspace ?? const [];
    final isMember = workspace.any(
      (entry) => Glob(path.posix.normalize(entry)).matches(packageDir),
    );
    if (!isMember) {
      throw StateError(
        'Workspace member $packageDir is not listed in the workspace of the '
        'repository root pubspec.yaml',
      );
    }

    return '.';
  }

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
