import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:meta/meta.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

@internal
extension ContextRootX on ContextRoot {
  static final _pubspecExpando = Expando<Pubspec>();
  static final _libExpando = Expando<Folder>();
  static final _srcExpando = Expando<Folder>();
  static final _testExpando = Expando<Folder>();

  Pubspec get pubspec => _pubspecExpando[this] ??= () {
        final pubspecFile = _workspaceRoot.getChildAssumingFile('pubspec.yaml');
        assert(pubspecFile.exists, 'pubspec.yaml must exist');
        final pubspecData = pubspecFile.readAsStringSync();
        return Pubspec.parse(pubspecData);
      }();

  Folder get lib =>
      _libExpando[this] ??= _workspaceRoot.getChildAssumingFolder('lib');

  Folder get src =>
      _srcExpando[this] ??= _workspaceRoot.getChildAssumingFolder('lib/src');

  Folder get test =>
      _testExpando[this] ??= _workspaceRoot.getChildAssumingFolder('test');

  Folder get _workspaceRoot => resourceProvider.getFolder(workspace.root);
}
