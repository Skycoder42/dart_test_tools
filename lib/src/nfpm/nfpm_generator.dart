import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import 'changelog_converter.dart';
import 'version_converter.dart';

/// Generates a resolved `nfpm.yaml` and chglog changelog for a Dart package.
///
/// The generator reads the package's `pubspec.yaml` and a template `nfpm.yaml`,
/// writes the pubspec-derived values into a copy of the template, appends the
/// bundle tree, executable symlinks and license content entries, and writes the
/// result together with the converted changelog into the output directory.
///
/// It does not build or run nfpm — a downstream pipeline job does that, which
/// also resolves the remaining project-specific `${...}` placeholders left in
/// the template from its own environment.
class NfpmGenerator {
  static final _licenseRegExp = RegExp('license', caseSensitive: false);
  static final _changelogRegExp = RegExp('change.*log', caseSensitive: false);

  final ChangelogConverter _changelogConverter;

  /// Default constructor.
  const NfpmGenerator([this._changelogConverter = const ChangelogConverter()]);

  /// Generates the nfpm configuration and changelog.
  ///
  /// Reads the `pubspec.yaml` and [templateFile] from [inputDirectory], writes
  /// the generated `nfpm.yaml` and `changelog.yaml` into [outputDirectory] and
  /// uses [bundleRoot] as the `src` of the generated bundle tree entry.
  Future<void> generate({
    required Directory inputDirectory,
    required File templateFile,
    required Directory outputDirectory,
    required Directory bundleRoot,
  }) async {
    final pubspecFile = File.fromUri(
      inputDirectory.uri.resolve('pubspec.yaml'),
    );
    if (!pubspecFile.existsSync()) {
      throw Exception('$pubspecFile not found!');
    }
    if (!templateFile.existsSync()) {
      throw Exception('$templateFile not found!');
    }

    final pubspecYaml = await pubspecFile.readAsString();
    final pubspec = Pubspec.parse(pubspecYaml, sourceUrl: pubspecFile.uri);
    final executables = _readExecutables(pubspecYaml);

    final editor = YamlEditor(await templateFile.readAsString());
    await outputDirectory.create(recursive: true);

    _applyMetadata(editor, pubspec);
    _applyVersion(editor, pubspec);

    _ensureContents(editor);
    _addBundleTree(editor, pubspec, bundleRoot);
    _addSymlinks(editor, pubspec, executables);
    _addLicense(editor, pubspec, inputDirectory);
    final changelogWritten = await _addChangelog(
      editor,
      inputDirectory,
      outputDirectory,
    );

    final nfpmFile = File.fromUri(outputDirectory.uri.resolve('nfpm.yaml'));
    await nfpmFile.writeAsString(editor.toString());

    print(p.basename(nfpmFile.path));
    if (changelogWritten) {
      print('changelog.yaml');
    }
  }

  Map<String, String> _readExecutables(String pubspecYaml) {
    final doc = loadYaml(pubspecYaml);
    if (doc is! YamlMap) {
      throw Exception('Invalid pubspec.yaml!');
    }

    final executables = doc['executables'];
    if (executables is! YamlMap || executables.isEmpty) {
      throw Exception('pubspec.yaml must define at least one executable!');
    }

    final result = <String, String>{};
    for (final entry in executables.entries) {
      final command = entry.key as String;
      final source = entry.value as String?;
      result[command] = source ?? command;
    }
    return result;
  }

  void _applyMetadata(YamlEditor editor, Pubspec pubspec) {
    if (!_isSet(editor, 'name')) {
      editor.update(['name'], pubspec.name);
    }
    if (!_isSet(editor, 'description')) {
      editor.update(['description'], pubspec.description ?? '');
    }
    if (!_isSet(editor, 'homepage')) {
      final homepage = pubspec.homepage ?? pubspec.repository?.toString();
      if (homepage != null) {
        editor.update(['homepage'], homepage);
      }
    }
  }

  bool _isSet(YamlEditor editor, String key) {
    final value = editor.parseAt([
      key,
    ], orElse: () => wrapAsYamlNode(null)).value;
    return value is String && value.trim().isNotEmpty && !value.contains(r'${');
  }

  void _applyVersion(YamlEditor editor, Pubspec pubspec) {
    final version = pubspec.version;
    if (version == null) {
      throw Exception('pubspec.yaml must define a version!');
    }

    final nfpmVersion = convertVersion(version);
    editor.update(['version'], nfpmVersion.version);
    if (nfpmVersion.prerelease case final String prerelease) {
      editor.update(['prerelease'], prerelease);
    }
    if (nfpmVersion.release case final String release) {
      editor.update(['release'], release);
    }
  }

  void _ensureContents(YamlEditor editor) {
    final contents = editor.parseAt([
      'contents',
    ], orElse: () => wrapAsYamlNode(null));
    if (contents is! YamlList) {
      editor.update(['contents'], <Object?>[]);
    }
  }

  void _addBundleTree(
    YamlEditor editor,
    Pubspec pubspec,
    Directory bundleRoot,
  ) => editor.appendToList(
    ['contents'],
    {
      'src': _absolute(bundleRoot.path),
      'dst': '/opt/${pubspec.name}',
      'type': 'tree',
    },
  );

  void _addSymlinks(
    YamlEditor editor,
    Pubspec pubspec,
    Map<String, String> executables,
  ) {
    for (final MapEntry(key: command, value: source) in executables.entries) {
      editor.appendToList(
        ['contents'],
        {
          'src': '/opt/${pubspec.name}/bin/$source',
          'dst': '/usr/bin/$command',
          'type': 'symlink',
        },
      );
    }
  }

  void _addLicense(YamlEditor editor, Pubspec pubspec, Directory inputDir) {
    final licenseFile = _findByPattern(inputDir, _licenseRegExp);
    if (licenseFile == null) {
      return;
    }

    // A regular file (no `type`), because nfpm's `type: license` only emits the
    // file for rpm packages and omits it entirely from deb and apk packages.
    final licenseName = p.basename(licenseFile.path);
    editor.appendToList(
      ['contents'],
      {
        'src': _absolute(licenseFile.path),
        'dst': '/usr/share/licenses/${pubspec.name}/$licenseName',
      },
    );
  }

  Future<bool> _addChangelog(
    YamlEditor editor,
    Directory inputDirectory,
    Directory outputDirectory,
  ) async {
    final changelogFile = _findByPattern(inputDirectory, _changelogRegExp);
    if (changelogFile == null) {
      return false;
    }

    final changelogYaml = await _changelogConverter.convert(
      changelogFile,
      packager: _readMaintainer(editor),
    );

    final outFile = File.fromUri(outputDirectory.uri.resolve('changelog.yaml'));
    await outFile.writeAsString(changelogYaml);

    editor.update(['changelog'], _absolute(outFile.path));
    return true;
  }

  String _readMaintainer(YamlEditor editor) {
    final maintainer = editor.parseAt([
      'maintainer',
    ], orElse: () => wrapAsYamlNode(null)).value;
    return maintainer is String ? maintainer : '';
  }

  File? _findByPattern(Directory directory, Pattern pattern) {
    for (final entity in directory.listSync()) {
      if (entity is File && p.basename(entity.path).contains(pattern)) {
        return entity;
      }
    }
    return null;
  }

  String _absolute(String path) => p.normalize(p.absolute(path));
}
