import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:path/path.dart';

import '../models/analysis_options.dart';
import '../models/analysis_options_ref.dart';
import '../models/pub_deps.dart';

class AnalysisOptionsLoader {
  final _pubCacheDir = Directory(
    join(
      Platform.environment['PUB_CACHE'] ??
          '${Platform.environment['HOME']}/.pub-cache',
      'hosted/pub.dartlang.org',
    ),
  );

  Future<AnalysisOptions> load(
    AnalysisOptionsRef analysisOptionsRef, {
    Directory? relativeTo,
  }) =>
      analysisOptionsRef.when(
        package: _loadPackage,
        local: (path) => _loadLocal(path, relativeTo),
      );

  Directory? findDirectory(
    AnalysisOptionsRef analysisOptionsRef, {
    Directory? relativeTo,
  }) =>
      analysisOptionsRef.whenOrNull(
        local: (path) => _resolveLocalFile(path, relativeTo).parent,
      );

  Future<AnalysisOptions> _loadLocal(String path, Directory? relativeTo) =>
      _parse(_resolveLocalFile(path, relativeTo));

  Future<AnalysisOptions> _loadPackage(String packageName, String path) async {
    final file = await _resolvePackageFile(packageName, path);
    return _parse(file);
  }

  Future<AnalysisOptions> _parse(File analysisOptionsFile) async {
    final analysisOptionsYaml = await analysisOptionsFile.readAsString();
    return checkedYamlDecode(
      analysisOptionsYaml,
      AnalysisOptions.fromYaml,
      sourceUrl: analysisOptionsFile.uri,
    );
  }

  File _resolveLocalFile(String path, Directory? relativeTo) =>
      relativeTo != null
          ? File.fromUri(relativeTo.uri.resolve(path))
          : File(path);

  Future<File> _resolvePackageFile(String packageName, String path) async {
    final pubDeps = await _loadPackages();
    final package = pubDeps.packages.firstWhere(
      (package) => package.name == packageName,
      orElse: () => throw Exception('$packageName is not a know dependency'),
    );

    if (package.source != 'hosted') {
      throw Exception('Can only resolve hosted packages');
    }

    return File.fromUri(
      _pubCacheDir.uri.resolve(
        join('$packageName-${package.version}', 'lib', path),
      ),
    );
  }

  PubDeps? _pubDeps;
  Future<PubDeps> _loadPackages() async {
    if (_pubDeps != null) {
      return _pubDeps!;
    }

    final pubDepsProcess = await Process.start('dart', const [
      'pub',
      'deps',
      '--json',
    ]);
    unawaited(stderr.addStream(pubDepsProcess.stderr));

    final pubDeps = await pubDepsProcess.stdout
        .transform(utf8.decoder)
        .transform(json.decoder)
        .cast<Map<String, dynamic>>()
        .map(PubDeps.fromJson)
        .single;

    final exitCode = await pubDepsProcess.exitCode;
    if (exitCode != 0) {
      throw Exception('pub deps failed with exit code: $exitCode');
    }

    return _pubDeps = pubDeps;
  }
}
