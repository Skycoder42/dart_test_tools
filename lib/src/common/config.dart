import 'dart:io';

import 'package:yaml/yaml.dart';

class PathConfig {
  final List<String> paths;

  const PathConfig([this.paths = const []]);

  factory PathConfig.fromYaml(dynamic yaml) {
    if (yaml is Iterable<dynamic>) {
      return PathConfig(yaml.cast<String>().toList());
    } else {
      return PathConfig([yaml as String]);
    }
  }
}

class DartTestToolsConfig {
  static Future<Map<dynamic, dynamic>> readYaml(String path) async {
    final configFile = File(path);
    final yaml = loadYaml(
      await configFile.readAsString(),
      sourceUrl: configFile.uri,
    );
    return yaml as Map<dynamic, dynamic>;
  }

  static Future<Map<dynamic, dynamic>> readYamlFor(
    String path,
    String key,
  ) async {
    final yaml = await readYaml(path);
    return (yaml[key] as Map<dynamic, dynamic>?) ?? const {};
  }
}
