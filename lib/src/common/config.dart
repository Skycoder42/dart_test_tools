import 'dart:io';

import 'package:yaml/yaml.dart';

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
