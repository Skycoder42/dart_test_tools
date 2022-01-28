import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

extension ContextRootX on ContextRoot {
  static final _pubspecExpando = Expando<Pubspec>();
  static final _libExpando = Expando<Folder>();
  static final _srcExpando = Expando<Folder>();
  static final _testExpando = Expando<Folder>();

  Pubspec get pubspec => _pubspecExpando[this] ??= () {
        final pubspecFile = root.getChildAssumingFile('pubspec.yaml');
        assert(pubspecFile.exists);
        final pubspecData = pubspecFile.readAsStringSync();
        return Pubspec.parse(pubspecData);
      }();

  Folder get lib => _libExpando[this] ??= root.getChildAssumingFolder('lib');

  Folder get src =>
      _srcExpando[this] ??= root.getChildAssumingFolder('lib/src');

  Folder get test => _testExpando[this] ??= root.getChildAssumingFolder('test');
}
