import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

@internal
enum RenovatePreset({required final bool flutterCompat}) {
  library(flutterCompat: true),
  application(flutterCompat: false);

  @visibleForTesting
  static const configFileNames = [
    'renovate.json',
    'renovate.json5',
    '.github/renovate.json',
    '.github/renovate.json5',
    '.gitlab/renovate.json',
    '.gitlab/renovate.json5',
    '.renovaterc',
    '.renovaterc.json',
    '.renovaterc.json5',
  ];

  static final _presetPattern = RegExp(
    r'''github>Skycoder42/dart_test_tools//renovate/(library|application)\b''',
  );

  static Future<RenovatePreset> detect(Directory repository) async {
    for (final name in configFileNames) {
      final file = File(path.join(repository.path, name));
      if (!file.existsSync()) {
        continue;
      }

      final presets = _presetPattern
          .allMatches(await file.readAsString())
          .map((m) => RenovatePreset.values.byName(m.group(1)!))
          .toSet();
      return switch (presets.toList()) {
        [final preset] => preset,
        [] => throw FormatException(
          '$name does not extend '
          'github>Skycoder42/dart_test_tools//renovate/library or '
          'github>Skycoder42/dart_test_tools//renovate/application',
        ),
        _ => throw FormatException(
          '$name extends both the library and the application preset',
        ),
      };
    }

    throw FormatException(
      'No Renovate config file found in ${repository.path} '
      '(looked for ${configFileNames.join(', ')})',
    );
  }
}
