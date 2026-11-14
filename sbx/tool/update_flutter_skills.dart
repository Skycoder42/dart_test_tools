// Regenerates the derived args of the Flutter sbx kit.
//
// Reads the pinned Flutter version and the pinned commits of dart-lang/skills
// and flutter/agent-plugins from sbx/flutter/flutter.yaml, then
// - sets the `dartVersion` arg to the Dart SDK that Flutter release ships with
//   (according to Flutter's release index), and
// - lists the dart-* and flutter-* skills at exactly the pinned commits and
//   rewrites the `skills` arg and the agent-skill@1 capabilities to match.
// Run from the repository root:
//
//   dart run sbx/tool/update_flutter_skills.dart [--file <path>]
//
// The Flutter version and the commits are the input and are never changed by
// this tool. Renovate bumps them and runs this tool as the pre-build command
// (see `renovate.pre_build_command` in pubspec.yaml).
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dart_test_tools/src/tools/github.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

final _dartSkillsUrl = Uri.https('github.com', '/dart-lang/skills.git');
final _flutterSkillsUrl = Uri.https('github.com', '/flutter/agent-plugins.git');
final _flutterReleasesUrl = Uri.https(
  'storage.googleapis.com',
  '/flutter_infra_release/releases/releases_linux.json',
);
const _capabilitiesKey = 'capabilities';
const _skillType = 'com.docker.sandbox/agent-skill@1';
const _skillPathPrefix = '/opt/flutter-skills/';
final _unorderedEquals = const UnorderedIterableEquality<String>().equals;

Future<void> main(List<String> args) => Github.runZoned(() async {
  final parser = ArgParser()
    ..addOption(
      'file',
      abbr: 'f',
      valueHelp: 'path',
      defaultsTo: 'sbx/flutter/flutter.yaml',
      help: 'The kit descriptor to update.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);
    if (options['help'] as bool) {
      stdout
        ..writeln('Usage: dart run sbx/tool/update_flutter_skills.dart')
        ..writeln(parser.usage);
      return;
    }

    final file = File(options['file'] as String);
    final editor = YamlEditor(await file.readAsString());

    await _updateDartVersion(editor);

    final dartRef = _ref(editor, 'dartSkillsRef');
    final flutterRef = _ref(editor, 'flutterSkillsRef');
    final skills = await _discoverSkills(dartRef, flutterRef).toList()
      ..sort(); // only relevant if actually updated

    _updateSkillsArg(editor, skills);
    _updateSkillEntries(editor, skills);

    if (editor.edits.isEmpty) {
      Github.logInfo('${file.path} is up to date (${skills.length} skills).');
      return;
    }

    await file.writeAsString(editor.toString());
    Github.logNotice('Updated ${file.path} (${skills.length} skills).');
  } on ArgParserException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln(parser.usage);
    exitCode = 64;
  }
});

String _ref(YamlEditor editor, String key) {
  final ref = (editor.parseAt(['args', key, 'default']) as YamlScalar?)?.value;
  if (ref is! String || !RegExp(r'^[0-9a-f]{40}$').hasMatch(ref)) {
    throw FormatException('args.$key.default is not a commit SHA', ref);
  }
  return ref;
}

Version _version(YamlEditor editor, String key) {
  final version =
      (editor.parseAt(['args', key, 'default']) as YamlScalar?)?.value;
  if (version is! String) {
    throw FormatException('args.$key.default is not string', version);
  }
  return .parse(version);
}

Future<void> _updateDartVersion(YamlEditor editor) async {
  final flutterVersion = _version(editor, 'flutterVersion');
  final currentDartVersion = _version(editor, 'dartVersion');

  Github.logInfo('Fetching $_flutterReleasesUrl');
  final response = await http.get(_flutterReleasesUrl);
  if (response.statusCode != 200) {
    throw Exception(
      'Failed to fetch $_flutterReleasesUrl: ${response.statusCode}',
    );
  }

  final index = json.decode(response.body) as Map<String, dynamic>;
  final release = (index['releases'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhereOrNull((r) => _tryParse(r['version']) == flutterVersion);
  if (release == null) {
    throw Exception('Flutter $flutterVersion does not exist');
  }

  final dartVersion = Version.parse(release['dart_sdk_version'] as String);

  if (dartVersion == currentDartVersion) {
    Github.logDebug(
      'args.dartVersion.default is up to date (Dart $dartVersion).',
    );
    return;
  }

  Github.logInfo(
    'Updating args.dartVersion.default: $currentDartVersion -> $dartVersion '
    '(Flutter $flutterVersion).',
  );
  editor.update(const [
    'args',
    'dartVersion',
    'default',
  ], YamlScalar.wrap(dartVersion, style: .DOUBLE_QUOTED));
}

Stream<String> _discoverSkills(String dartRef, String flutterRef) async* {
  final tmp = await Directory.systemTemp.createTemp();
  try {
    final dartRepo = await _fetch(
      tmp,
      'dart-skills',
      _dartSkillsUrl.toString(),
      dartRef,
    );
    yield* _listSkills(dartRepo, 'dart-');

    final flutterRepo = await _fetch(
      tmp,
      'flutter-skills',
      _flutterSkillsUrl.toString(),
      flutterRef,
    );
    yield* _listSkills(flutterRepo, 'flutter-');
  } finally {
    await tmp.delete(recursive: true);
  }
}

Future<Directory> _fetch(
  Directory tmp,
  String name,
  String url,
  String sha,
) async {
  final dir = Directory.fromUri(tmp.uri.resolve(name));
  Github.logInfo('Fetching $url@$sha');
  await Github.exec('git', ['init', '-q', dir.path]);
  await Github.exec('git', [
    'fetch',
    '-q',
    '--depth',
    '1',
    url,
    sha,
  ], workingDirectory: dir);
  await Github.exec('git', const [
    'checkout',
    '-q',
    'FETCH_HEAD',
  ], workingDirectory: dir);
  final head = await Github.execLines(
    'git',
    const ['rev-parse', 'HEAD'],
    workingDirectory: dir,
  ).map((l) => l.trim()).where((l) => l.isNotEmpty).firstOrNull;
  if (head != sha) {
    throw Exception('Fetched $head from $url, expected $sha.');
  }
  return dir;
}

Stream<String> _listSkills(Directory repo, String prefix) async* {
  final skillsDir = Directory('${repo.path}/skills');
  if (!skillsDir.existsSync()) {
    throw Exception('${skillsDir.path} does not exist.');
  }

  await for (final entity in skillsDir.list(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entity is! Directory || !name.startsWith(prefix)) {
      continue;
    }

    yield name;
  }
}

void _updateSkillsArg(YamlEditor editor, List<String> skills) {
  const skillsArg = ['args', 'skills', 'default'];
  final node = editor.parseAt(skillsArg);
  if (node case YamlScalar(:final String value)) {
    final currentSkills = LineSplitter.split(value)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    if (_unorderedEquals(currentSkills, skills)) {
      Github.logDebug(
        'args.skills.default is up to date (${skills.length} skills).',
      );
      return;
    }

    Github.logInfo('Updating args.skills.default (${skills.length} skills).');
    editor.update(
      skillsArg,
      YamlScalar.wrap(skills.join('\n'), style: .LITERAL),
    );
    return;
  }

  throw Exception(
    'args.skills.default must be a string '
    'but was ${node.runtimeType} (${node.value.runtimeType}).',
  );
}

void _updateSkillEntries(YamlEditor editor, List<String> skills) {
  final indicesToRemove = (editor.parseAt([_capabilitiesKey]) as YamlList)
      .cast<YamlMap>()
      .indexed
      .where((r) => r.$2['type'] == _skillType)
      .map((r) => (r.$1, r.$2['config'] as YamlMap))
      .map((r) => (r.$1, r.$2['path'] as String))
      .where((r) => r.$2.startsWith(_skillPathPrefix))
      .map((r) => (r.$1, r.$2.substring(_skillPathPrefix.length)))
      .toList();

  if (_unorderedEquals(indicesToRemove.map((r) => r.$2), skills)) {
    Github.logDebug(
      'agent-skill@1 capabilities are up to date (${skills.length} skills).',
    );
    return;
  }

  indicesToRemove.sort((a, b) => a.$1.compareTo(b.$1));
  for (final (index, _) in indicesToRemove.reversed) {
    editor.remove([_capabilitiesKey, index]);
  }

  for (final skill in skills) {
    editor.appendToList(
      [_capabilitiesKey],
      {
        'type': _skillType,
        'optional': true,
        'config': {'path': '$_skillPathPrefix$skill'},
      },
    );
  }

  Github.logInfo(
    'Updated agent-skill@1 capabilities (${skills.length} skills).',
  );
}

Version? _tryParse(dynamic version) {
  try {
    return Version.parse(version as String);
    // ignore: avoid_catches_without_on_clauses try parse
  } catch (_) {
    return null;
  }
}
