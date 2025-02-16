import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:meta/meta.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../tools/io.dart';
import 'cask_options.dart';

@internal
class CaskOptionsLoader {
  const CaskOptionsLoader();

  Future<CaskOptions> load(Directory sourceDir) async {
    final pubspecFile = sourceDir.subFile('pubspec.yaml');
    final pubspecYaml = await pubspecFile.readAsString();

    final pubspec = Pubspec.parse(pubspecYaml, sourceUrl: pubspecFile.uri);

    final view = checkedYamlDecode(
      pubspecYaml,
      CaskOptionsPubspecView.fromYaml,
      sourceUrl: pubspecFile.uri,
    );

    final appInfoFile = sourceDir
        .subDir('macos')
        .subDir('Runner')
        .subDir('Configs')
        .subFile('AppInfo.xcconfig');
    final appInfo = await _readAppInfo(appInfoFile);

    return CaskOptions(pubspec: pubspec, options: view.cask, appInfo: appInfo);
  }

  Future<AppInfoOptions> _readAppInfo(File file) async {
    final outMap = <String, String>{};

    final stream = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((l) => l.trim());
    await for (final line in stream) {
      if (line.isEmpty || line.startsWith('//')) {
        continue;
      }

      final equalsIndex = line.indexOf('=');
      if (equalsIndex == -1) {
        throw FormatException('Invalid line in AppInfo.xcconfig', line);
      }

      final key = line.substring(0, equalsIndex).trimRight();
      final value = line.substring(equalsIndex + 1).trimLeft();
      outMap[key] = value;
    }

    return AppInfoOptions.fromJson(outMap);
  }
}
