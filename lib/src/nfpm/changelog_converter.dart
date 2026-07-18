import 'dart:io';

import 'package:change/change.dart';
import 'package:meta/meta.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Converts a cider-managed `CHANGELOG.md` into the nfpm chglog YAML format.
///
/// See https://github.com/goreleaser/chglog for the target format.
@internal
class ChangelogConverter {
  /// Default constructor.
  const ChangelogConverter();

  /// Parses [changelogFile] and returns the chglog YAML representation.
  ///
  /// Releases are emitted newest first and [packager] is written verbatim into
  /// every changelog entry.
  Future<String> convert(File changelogFile, {required String packager}) async {
    final changelog = parseChangelog(await changelogFile.readAsString());

    final entries = changelog
        .history()
        .toList()
        .reversed
        .map((release) => _convertRelease(release, packager))
        .toList();

    return YamlWriter().write(entries);
  }

  Map<String, Object?> _convertRelease(Release release, String packager) => {
    'semver': release.version.toString(),
    'date': _formatDate(release.date),
    'packager': packager,
    'changes': [
      for (final change in release.changes())
        {'note': '${change.type}: $change'},
    ],
  };

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-${day}T00:00:00Z';
  }
}
