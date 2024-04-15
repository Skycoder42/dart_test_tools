import 'dart:io';
import 'dart:math';

import 'package:dart_test_tools/src/tools/github.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class BuildNumberGenerator {
  const BuildNumberGenerator();

  Future<void> call({
    int minorWidth = 2,
    int patchWidth = 2,
    bool asEnv = false,
  }) async {
    final pubspecFile = File('pubspec.yaml');
    final pubspec = Pubspec.parse(
      await pubspecFile.readAsString(),
      sourceUrl: pubspecFile.uri,
    );

    Github.logInfo('Detected app version as ${pubspec.version}');
    final Version(major: major, minor: minor, patch: patch) = pubspec.version!;

    final buildNumber = _padFilled('major', major, 0) +
        _padFilled('minor', minor, minorWidth) +
        _padFilled('patch', patch, patchWidth);

    Github.logInfo('Generated build number as $buildNumber');

    if (asEnv) {
      await Github.env.setOutput('BUILD_NUMBER', buildNumber, asEnv: true);
    } else {
      await Github.env.setOutput('buildNumber', buildNumber);
    }
  }

  String _padFilled(String name, int number, int width) {
    if (width > 0 && number >= pow(10, width)) {
      throw Exception(
        'Version number does not fit! '
        'Segment $name ($number) has more then $width digits',
      );
    }
    return number.toRadixString(10).padLeft(width, '0');
  }
}
