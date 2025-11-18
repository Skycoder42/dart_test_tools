import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/workspace/workspace.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class _WorkspacePackageExtra {
  Folder? lib;
  Folder? libSrc;
  Folder? libGen;
  Folder? tool;
  Pubspec? pubspec;
}

extension WorkspacePackageX on WorkspacePackage {
  static final _expando = Expando<_WorkspacePackageExtra>();

  Folder get lib => _extra.lib ??= root.getChildAssumingFolder('lib');

  Folder get libSrc => _extra.libSrc ??= lib.getChildAssumingFolder('src');

  Folder get libGen => _extra.libGen ??= lib.getChildAssumingFolder('gen');

  Folder get tool => _extra.tool ??= root.getChildAssumingFolder('tool');

  Pubspec? get pubspec => _extra.pubspec ??= _loadPubspec();

  _WorkspacePackageExtra get _extra =>
      _expando[this] ??= _WorkspacePackageExtra();

  Pubspec? _loadPubspec() {
    final pubspecFile = root.getChildAssumingFile('pubspec.yaml');
    if (!pubspecFile.exists) {
      return null;
    }

    return Pubspec.parse(
      pubspecFile.readAsStringSync(),
      sourceUrl: pubspecFile.toUri(),
      lenient: true,
    );
  }
}
