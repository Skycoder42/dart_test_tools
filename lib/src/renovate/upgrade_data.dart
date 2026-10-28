import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import 'models/renovate_upgrade.dart';

@internal
sealed class UpgradeData._() {
  static const dataFileEnvVar = 'RENOVATE_POST_UPGRADE_COMMAND_DATA_FILE';

  static Future<List<RenovateUpgrade>> load(File file) async {
    final data = json.decode(await file.readAsString()) as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(RenovateUpgrade.fromJson)
        .toList();
  }

  static Future<List<RenovateUpgrade>> fromEnvironment([
    @visibleForTesting Map<String, String>? environment,
  ]) {
    final path = (environment ?? Platform.environment)[dataFileEnvVar];
    if (path == null) {
      throw StateError('Environment variable $dataFileEnvVar is not set');
    }
    return load(File(path));
  }
}
