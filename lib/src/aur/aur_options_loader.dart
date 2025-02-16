import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'aur_options.dart';

@internal
class AurOptionsLoader {
  static final _changelogRegex = RegExp('change.*log', caseSensitive: false);
  static final _licenseRegexp = RegExp('license', caseSensitive: false);

  const AurOptionsLoader();

  Future<PubspecWithAur> loadAurOptions(Directory projectDirectory) async {
    final pubspecFile = File.fromUri(
      projectDirectory.uri.resolve('pubspec.yaml'),
    );

    if (!pubspecFile.existsSync()) {
      throw Exception('$pubspecFile not found!');
    }

    final pubspecYaml = await pubspecFile.readAsString();

    final pubspec = Pubspec.parse(pubspecYaml, sourceUrl: pubspecFile.uri);

    final aurOptionsPubspecView = checkedYamlDecode(
      pubspecYaml,
      AurOptionsPubspecView.fromYaml,
      sourceUrl: pubspecFile.uri,
    );

    return PubspecWithAur(
      pubspec: pubspec,
      aurOptions: aurOptionsPubspecView.aur,
      executables: aurOptionsPubspecView.executables,
    );
  }

  File? findByName(Directory projectDirectory, String? name) {
    if (name != null) {
      return File.fromUri(projectDirectory.uri.resolve(name));
    } else {
      return null;
    }
  }

  Future<File?> findChangelog(Directory projectDirectory) =>
      _findByPattern(projectDirectory, _changelogRegex);

  Future<File?> findLicense(Directory projectDirectory) =>
      _findByPattern(projectDirectory, _licenseRegexp);

  Future<File?> _findByPattern(Directory projectDirectory, Pattern pattern) {
    if (!projectDirectory.existsSync()) {
      throw Exception('$projectDirectory must be an existing directory!');
    }

    return projectDirectory
        .list()
        .where((e) => e is File)
        .cast<File?>()
        .firstWhere(
          (file) => basename(file!.path).contains(pattern),
          orElse: () => null,
        );
  }
}
