import 'dart:io';

import 'package:dart_test_tools/src/tools/github.dart';
import 'package:pub_semver/pub_semver.dart';

import 'ci_gen/common/tools.dart';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  final updates = <String, String>{};

  // Deduplicate by two-segment repo so each remote is queried only once.
  final repoTags = <String, List<(String, Version)>>{};
  for (final spec in Tools.toolSpecs.keys) {
    final repo = _repoFromSpec(spec);
    if (!repoTags.containsKey(repo)) {
      repoTags[repo] = await _fetchVersionTags(repo);
    }
  }

  for (final spec in Tools.toolSpecs.keys) {
    final atIndex = spec.lastIndexOf('@');
    final currentPin = spec.substring(atIndex + 1);
    final repo = _repoFromSpec(spec);
    final actionPath = spec.substring(0, atIndex);

    final newPin = _latestPin(repoTags[repo]!);
    if (newPin != null && newPin != currentPin) {
      updates[spec] = '$actionPath@$newPin';
    }
  }

  if (updates.isEmpty) {
    stdout.writeln('All actions are up to date.');
    return;
  }

  for (final entry in updates.entries) {
    stdout.writeln('${entry.key} -> ${entry.value}');
  }

  if (dryRun) return;

  final toolsFile = File('tool/ci_gen/common/tools.dart');
  var content = await toolsFile.readAsString();
  for (final entry in updates.entries) {
    content = content.replaceAll("'${entry.key}'", "'${entry.value}'");
  }
  await toolsFile.writeAsString(content);
}

String _repoFromSpec(String spec) {
  final atIndex = spec.lastIndexOf('@');
  final actionPath = spec.substring(0, atIndex);
  final parts = actionPath.split('/');
  return '${parts[0]}/${parts[1]}';
}

String _toSemver(String versionStr) {
  final parts = versionStr.split('.');
  while (parts.length < 3) {
    parts.add('0');
  }
  return parts.join('.');
}

/// Fetches all stable, parseable version tags for [repo] as (rawTag, Version)
/// pairs, sorted ascending.
Future<List<(String, Version)>> _fetchVersionTags(String repo) async {
  final lines = await Github.execLines('git', [
    'ls-remote',
    '--tags',
    'https://github.com/$repo.git',
  ]).toList();

  final result = <(String, Version)>[];
  for (final line in lines) {
    if (line.contains('^{}')) continue;
    final rawRef = line.split('\t').last;
    if (!rawRef.startsWith('refs/tags/')) continue;
    final rawTag = rawRef.substring('refs/tags/'.length);
    final versionStr = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
    Version version;
    try {
      version = Version.parse(_toSemver(versionStr));
    } on FormatException {
      continue;
    }
    if (version.isPreRelease) continue;
    result.add((rawTag, version));
  }
  result.sort((a, b) => a.$2.compareTo(b.$2));
  return result;
}

/// Determines the best pin string from the available version tags.
String? _latestPin(List<(String, Version)> tags) {
  if (tags.isEmpty) return null;

  // Group by major, take the highest-major group.
  final byMajor = <int, List<(String, Version)>>{};
  for (final entry in tags) {
    byMajor.putIfAbsent(entry.$2.major, () => []).add(entry);
  }
  final maxMajor = byMajor.keys.reduce((a, b) => a > b ? a : b);
  final group = byMajor[maxMajor]!;

  // Prefer the floating major tag (e.g. 'v7') when one exists.
  final floatingTag = group
      .where((e) => e.$2.minor == 0 && e.$2.patch == 0)
      .where((e) => e.$1 == 'v${e.$2.major}')
      .firstOrNull;
  if (floatingTag != null) return floatingTag.$1;

  // Otherwise use the raw tag of the highest version in the group.
  return group.last.$1;
}
